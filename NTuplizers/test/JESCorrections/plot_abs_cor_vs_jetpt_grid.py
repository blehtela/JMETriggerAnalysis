#!/usr/bin/env python3

import ROOT
import argparse
import math
import os
import re

ROOT.gROOT.SetBatch(True)
ROOT.gStyle.SetOptStat(0)
ROOT.gStyle.SetOptFit(0)

TARGET = "AbsCorVsJetPt"


def eta_key(text):
    """
    Handles names like:
      AbsCorVsJetPt_JetEta-0.4to0
      AbsCorVsJetPt_JetEta2to2.5
      AbsCorVsJetPt_JetEta-3--2.5
    """
    m = re.search(r"JetEta(-?\d+(?:\.\d+)?|m?\d+p\d+)to(-?\d+(?:\.\d+)?|m?\d+p\d+)", text)
    if not m:
        m = re.search(r"JetEta(-?\d+(?:\.\d+)?)-(-?\d+(?:\.\d+)?)", text)

    if not m:
        return None

    def conv(s):
        s = s.replace("m", "-").replace("p", ".")
        return float(s)

    return conv(m.group(1)), conv(m.group(2))


def eta_label(key):
    if key is None:
        return ""
    return f"{key[0]:g} < #eta < {key[1]:g}"


def is_graph(obj):
    return obj.InheritsFrom("TGraph")


def unique_name(base, idx):
    clean = re.sub(r"[^A-Za-z0-9_]", "_", base)
    return f"{clean}_{idx}"


def walk_directory(directory, prefix=""):
    for key in directory.GetListOfKeys():
        obj = key.ReadObj()
        path = f"{prefix}/{key.GetName()}" if prefix else key.GetName()

        yield path, obj

        if obj.InheritsFrom("TDirectory"):
            yield from walk_directory(obj, path)


def clone_attached_fits(graph, npx, tag):
    fits = []
    funcs = graph.GetListOfFunctions()

    if funcs:
        for obj in funcs:
            if obj.InheritsFrom("TF1"):
                f = obj.Clone(unique_name(obj.GetName(), tag))
                f.SetLineColor(ROOT.kRed + 1)
                f.SetLineWidth(2)
                f.SetNpx(npx)
                fits.append(f)

        # Avoid ROOT auto-redrawing the original low-Npx function.
        funcs.Clear()

    return fits


def graph_range(g):
    xs, ys = [], []

    for i in range(g.GetN()):
        x = float(g.GetPointX(i))
        y = float(g.GetPointY(i))

        exl = exh = eyl = eyh = 0.0

        if g.InheritsFrom("TGraphAsymmErrors"):
            exl = float(g.GetErrorXlow(i))
            exh = float(g.GetErrorXhigh(i))
            eyl = float(g.GetErrorYlow(i))
            eyh = float(g.GetErrorYhigh(i))
        elif g.InheritsFrom("TGraphErrors"):
            exl = exh = float(g.GetErrorX(i))
            eyl = eyh = float(g.GetErrorY(i))

        xs += [x - exl, x + exh]
        ys += [y - eyl, y + eyh]

    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)

    dx = xmax - xmin if xmax > xmin else 1.0
    dy = ymax - ymin if ymax > ymin else 1.0

    return xmin - 0.06 * dx, xmax + 0.06 * dx, ymin - 0.12 * dy, ymax + 0.18 * dy


def include_fit_in_yrange(f, xmin, xmax, ymin, ymax):
    fxmin = max(xmin, f.GetXmin())
    fxmax = min(xmax, f.GetXmax())

    if fxmax <= fxmin:
        return ymin, ymax

    for i in range(200):
        x = fxmin + (fxmax - fxmin) * i / 199.0
        y = f.Eval(x)
        if math.isfinite(y):
            ymin = min(ymin, y)
            ymax = max(ymax, y)

    return ymin, ymax


def collect_objects(root_file, npx):
    graphs = []
    external_fits = {}

    idx = 0

    for path, obj in walk_directory(root_file):
        name = obj.GetName()
        full = f"{path}/{name}"

        if TARGET not in full:
            continue

        key = eta_key(full)

        if is_graph(obj):
            g = obj.Clone(unique_name(name, idx))
            g.SetTitle("")
            fits = clone_attached_fits(g, npx, idx)

            graphs.append({
                "path": path,
                "name": name,
                "eta": key,
                "graph": g,
                "fits": fits,
            })

            idx += 1

        elif obj.InheritsFrom("TF1"):
            f = obj.Clone(unique_name(name, idx))
            f.SetLineColor(ROOT.kRed + 1)
            f.SetLineWidth(2)
            f.SetNpx(npx)

            if key is not None:
                external_fits.setdefault(key, []).append(f)

            idx += 1

    # If a graph has no attached TF1, try to match a standalone TF1 by eta bin.
    for item in graphs:
        if not item["fits"] and item["eta"] in external_fits:
            item["fits"] = [
                f.Clone(unique_name(f.GetName(), i))
                for i, f in enumerate(external_fits[item["eta"]])
            ]

    graphs.sort(key=lambda item: item["eta"] if item["eta"] is not None else (999, 999))

    return graphs


def style_graph(g):
    g.SetMarkerStyle(20)
    g.SetMarkerSize(0.65)
    g.SetLineColor(ROOT.kBlack)
    g.SetMarkerColor(ROOT.kBlack)
    g.SetLineWidth(1)


def style_frame(frame):
    frame.GetXaxis().SetTitle("p_{T}^{jet}")
    frame.GetYaxis().SetTitle("Absolute correction")

    frame.GetXaxis().SetTitleSize(0.045)
    frame.GetYaxis().SetTitleSize(0.045)
    frame.GetXaxis().SetLabelSize(0.04)
    frame.GetYaxis().SetLabelSize(0.04)

    frame.GetXaxis().SetTitleOffset(1.0)
    frame.GetYaxis().SetTitleOffset(1.25)


def draw_grid(items, output, cols, extend_fit_to_frame):
    n = len(items)
    rows = math.ceil(n / cols)

    c = ROOT.TCanvas(
        "c_abscor_grid",
        "AbsCorVsJetPt grid",
        520 * cols,
        420 * rows,
    )

    c.Divide(cols, rows, 0.001, 0.001)

    label = ROOT.TLatex()
    label.SetNDC()
    label.SetTextSize(0.055)

    warn = ROOT.TLatex()
    warn.SetNDC()
    warn.SetTextSize(0.045)
    warn.SetTextColor(ROOT.kRed + 1)

    for i, item in enumerate(items, start=1):
        c.cd(i)
        pad = ROOT.gPad

        pad.SetTicks(1, 1)
        pad.SetGrid(1, 1)
        pad.SetLeftMargin(0.14)
        pad.SetRightMargin(0.04)
        pad.SetTopMargin(0.08)
        pad.SetBottomMargin(0.13)

        g = item["graph"]
        fits = item["fits"]

        style_graph(g)

        xmin, xmax, ymin, ymax = graph_range(g)

        data_xmin, data_xmax = xmin, xmax

        for f in fits:
            f.SetNpx(2000)

            if extend_fit_to_frame:
                f.SetRange(data_xmin, data_xmax)

            ymin, ymax = include_fit_in_yrange(f, xmin, xmax, ymin, ymax)

        dy = ymax - ymin if ymax > ymin else 1.0
        ymin -= 0.05 * dy
        ymax += 0.08 * dy

        frame = pad.DrawFrame(xmin, ymin, xmax, ymax)
        style_frame(frame)

        g.Draw("P SAME")

        for f in fits:
            f.Draw("L SAME")

        if item["eta"] is not None:
            label.DrawLatex(0.18, 0.86, eta_label(item["eta"]))
        else:
            label.DrawLatex(0.18, 0.86, item["name"].replace(TARGET + "_", ""))

        if not fits:
            warn.DrawLatex(0.55, 0.86, "no TF1 found")

        pad.RedrawAxis()

    c.SaveAs(output)

    if output.lower().endswith(".pdf"):
        png = output[:-4] + ".png"
        c.SaveAs(png)

    print(f"\nSaved {output}")
    print(f"Found {len(items)} {TARGET} graphs")
    print(f"With fits: {sum(1 for x in items if x['fits'])}")
    print(f"Without fits: {sum(1 for x in items if not x['fits'])}")

    for item in items:
        if not item["fits"]:
            print("No fit found for:", item["path"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="input ROOT file")
    parser.add_argument("-o", "--output", default="AbsCorVsJetPt_grid.pdf")
    parser.add_argument("--cols", type=int, default=4)
    parser.add_argument("--npx", type=int, default=2000)
    parser.add_argument(
        "--extend-fit-to-frame",
        action="store_true",
        help="draw each TF1 over the full visible graph x range",
    )

    args = parser.parse_args()

    f = ROOT.TFile.Open(args.input)
    if not f or f.IsZombie():
        raise RuntimeError(f"Could not open {args.input}")

    items = collect_objects(f, args.npx)

    if not items:
        raise RuntimeError(f"No {TARGET} graphs found")

    draw_grid(
        items=items,
        output=args.output,
        cols=args.cols,
        extend_fit_to_frame=args.extend_fit_to_frame,
    )

    f.Close()


if __name__ == "__main__":
    main()