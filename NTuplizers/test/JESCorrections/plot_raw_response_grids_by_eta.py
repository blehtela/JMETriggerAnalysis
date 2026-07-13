#!/usr/bin/env python3

import argparse
import math
import os
import re
from collections import defaultdict

import ROOT

ROOT.gROOT.SetBatch(True)
ROOT.gStyle.SetOptStat(0)


RAW_RESPONSE_RE = re.compile(
    r"^RelRsp_JetEta(?P<eta>.+?)_RefPt(?P<ptmin>[-+0-9.]+)to(?P<ptmax>[-+0-9.]+)$"
)


def safe_name(s):
    return (
        s.replace(".", "p")
         .replace("-", "m")
         .replace("+", "p")
         .replace("to", "_to_")
         .replace("/", "_")
    )


def parse_float(x):
    try:
        return float(x)
    except ValueError:
        return 0.0


def make_grid_for_eta(eta_key, entries, outdir, alg, normalize=False, logy=False, out_ext="png"):
    entries = sorted(entries, key=lambda e: parse_float(e["ptmin"]))

    n = len(entries)
    ncols = 4
    nrows = int(math.ceil(float(n) / ncols))

    canvas_name = f"RawRelRsp_{alg}_{safe_name(eta_key)}"
    c = ROOT.TCanvas(canvas_name, canvas_name, 420 * ncols, 320 * nrows)
    c.Divide(ncols, nrows)

    # IMPORTANT: keep Python references alive
    keepalive = []

    for i, entry in enumerate(entries):
        pad = c.cd(i + 1)
        pad.SetTicks(1, 1)
        pad.SetLeftMargin(0.14)
        pad.SetBottomMargin(0.13)

        if logy:
            pad.SetLogy()

        h = entry["hist"].Clone(f"{entry['hist'].GetName()}_clone_{i}")
        h.SetDirectory(0)

        if normalize:
            integral = h.Integral()
            if integral > 0:
                h.Scale(1.0 / integral)

        h.SetLineColor(ROOT.kBlack)
        h.SetMarkerColor(ROOT.kBlack)
        h.SetMarkerStyle(20)
        h.SetMarkerSize(0.8)
        h.SetFillColor(ROOT.kAzure - 9)
        h.SetFillStyle(3001)

        h.GetXaxis().SetTitle("Relative response")
        h.GetXaxis().SetRangeUser(0.0, 2.0)
        h.GetYaxis().SetTitle("Normalized entries" if normalize else "Entries")
        h.GetXaxis().SetTitleSize(0.045)
        h.GetYaxis().SetTitleSize(0.045)
        h.GetXaxis().SetLabelSize(0.04)
        h.GetYaxis().SetLabelSize(0.04)
        h.GetYaxis().SetTitleOffset(1.35)

        title = f"{entry['ptmin']} < RefPt < {entry['ptmax']} GeV"
        h.SetTitle(title)

        h.Draw("HIST")

        latex1 = ROOT.TLatex(0.16, 0.84, alg)
        latex1.SetNDC()
        latex1.SetTextSize(0.045)
        latex1.Draw()

        latex2 = ROOT.TLatex(0.16, 0.78, eta_key.replace("JetEta", "JetEta "))
        latex2.SetNDC()
        latex2.SetTextSize(0.045)
        latex2.Draw()

        # Store refs so PyROOT does not delete them
        keepalive.append(h)
        keepalive.append(latex1)
        keepalive.append(latex2)

    # Hide unused pads
    for j in range(n, nrows * ncols):
        c.cd(j + 1)
        ROOT.gPad.Clear()

    os.makedirs(outdir, exist_ok=True)

    outpath = os.path.join(outdir, f"{canvas_name}.{out_ext}")

    c.Update()
    c.SaveAs(outpath)

    # Attach references to canvas too, extra safety
    c._keepalive = keepalive

    print(f"Wrote {outpath}")


def main():
    parser = argparse.ArgumentParser(
        description="Make raw RelRsp grids grouped by JetEta region using PyROOT."
    )

    parser.add_argument("rootfile", help="Input step1 ROOT file")
    parser.add_argument("--alg", required=True, help="Algorithm directory, e.g. ak4pfpuppiHLT")
    parser.add_argument("-o", "--outdir", default="raw_response_grids_by_eta")
    parser.add_argument("--normalize", action="store_true")
    parser.add_argument("--logy", action="store_true")
    parser.add_argument("--out-ext", default="png", choices=["png", "pdf", "root", "eps"])

    args = parser.parse_args()

    f = ROOT.TFile.Open(args.rootfile)
    if not f or f.IsZombie():
        raise RuntimeError(f"Could not open file: {args.rootfile}")

    d = f.Get(args.alg)
    if not d:
        raise RuntimeError(f"Could not find directory '{args.alg}' in {args.rootfile}")

    grouped = defaultdict(list)

    keys = d.GetListOfKeys()
    for key in keys:
        name = key.GetName()
        match = RAW_RESPONSE_RE.match(name)
        if not match:
            continue

        hist = d.Get(name)
        if not hist:
            continue

        eta_key = "JetEta" + match.group("eta")

        grouped[eta_key].append(
            {
                "ptmin": match.group("ptmin"),
                "ptmax": match.group("ptmax"),
                "hist": hist,
            }
        )

    if not grouped:
        raise RuntimeError(
            "No histograms matching RelRsp_JetEta..._RefPt...to... were found."
        )

    print(f"Found {len(grouped)} eta categories:")
    for eta_key in sorted(grouped.keys()):
        print(f"  {eta_key}: {len(grouped[eta_key])} pT bins")

    for eta_key in sorted(grouped.keys()):
        make_grid_for_eta(
            eta_key=eta_key,
            entries=grouped[eta_key],
            outdir=args.outdir,
            alg=args.alg,
            normalize=args.normalize,
            logy=args.logy,
            out_ext=args.out_ext,
        )

    f.Close()


if __name__ == "__main__":
    main()
