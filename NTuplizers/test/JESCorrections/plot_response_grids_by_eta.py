#!/usr/bin/env python3

import argparse
import math
import os
import re
from collections import defaultdict

import ROOT

ROOT.gROOT.SetBatch(True)
ROOT.gStyle.SetOptStat(0)


RESPONSE_RE = re.compile(
    r"^Response_(JetEta(?P<eta>.+?))_(?P<idx>\d+)_RefPt(?P<ptmin>[-+0-9.]+)to(?P<ptmax>[-+0-9.]+)$"
)


def safe_name(s):
    return (
        s.replace(".", "p")
         .replace("-", "m")
         .replace("+", "p")
         .replace("to", "_to_")
         .replace("/", "_")
         .replace(" ", "_")
    )


def make_grid_for_eta(
    eta_key,
    entries,
    outdir,
    alg,
    normalize=False,
    logy=False,
    out_ext="png",
    xmin=None,
    xmax=None,
):
    entries = sorted(entries, key=lambda x: x["idx"])

    n = len(entries)
    ncols = 4
    nrows = int(math.ceil(float(n) / ncols))

    canvas_name = f"ResponseDistributions_{alg}_{safe_name(eta_key)}"
    if normalize:
        canvas_name += "_norm"

    c = ROOT.TCanvas(canvas_name, canvas_name, 420 * ncols, 320 * nrows)
    c.Divide(ncols, nrows)

    # Important for PyROOT: keep drawn objects alive until SaveAs finishes
    keepalive = []

    for i, entry in enumerate(entries):
        pad = c.cd(i + 1)
        pad.SetTicks(1, 1)
        pad.SetLeftMargin(0.14)
        pad.SetRightMargin(0.05)
        pad.SetBottomMargin(0.13)
        pad.SetTopMargin(0.10)

        if logy:
            pad.SetLogy()

        h = entry["hist"].Clone(f"{entry['hist'].GetName()}_clone_{i}")
        h.SetDirectory(0)

        if normalize:
            integral = h.Integral()
            if integral > 0:
                h.Scale(1.0 / integral)

        h.SetTitle(f"{entry['ptmin']} < RefPt < {entry['ptmax']} GeV")
        h.GetXaxis().SetTitle("Response")
        h.GetYaxis().SetTitle("Normalized entries" if normalize else "Entries")

        h.GetXaxis().SetTitleSize(0.045)
        h.GetYaxis().SetTitleSize(0.045)
        h.GetXaxis().SetLabelSize(0.040)
        h.GetYaxis().SetLabelSize(0.040)
        h.GetYaxis().SetTitleOffset(1.35)
        h.GetXaxis().SetTitleOffset(1.05)

        if xmin is not None and xmax is not None:
            h.GetXaxis().SetRangeUser(xmin, xmax)
        elif xmax is not None:
            h.GetXaxis().SetRangeUser(0.0, xmax)

        h.SetLineColor(ROOT.kBlack)
        h.SetLineWidth(2)
        h.SetMarkerColor(ROOT.kBlack)
        h.SetMarkerStyle(20)
        h.SetMarkerSize(0.7)
        h.SetFillColor(ROOT.kAzure - 9)
        h.SetFillStyle(3001)

        # Histogram-style response distribution
        h.Draw("HIST")

        # Text labels like the previous PyROOT plot
        latex_alg = ROOT.TLatex(0.16, 0.84, alg)
        latex_alg.SetNDC()
        latex_alg.SetTextSize(0.045)
        latex_alg.SetTextFont(62)
        latex_alg.Draw()

        latex_eta = ROOT.TLatex(0.16, 0.78, eta_key.replace("JetEta", "JetEta "))
        latex_eta.SetNDC()
        latex_eta.SetTextSize(0.042)
        latex_eta.Draw()

        keepalive.extend([h, latex_alg, latex_eta])

    # Hide unused pads
    for j in range(n, nrows * ncols):
        c.cd(j + 1)
        ROOT.gPad.Clear()

    os.makedirs(outdir, exist_ok=True)

    outpath = os.path.join(outdir, f"{canvas_name}.{out_ext}")
    c.Update()
    c.SaveAs(outpath)

    # Extra safety: attach objects to canvas
    c._keepalive = keepalive

    print(f"Wrote {outpath}")


def main():
    parser = argparse.ArgumentParser(
        description="Make closure response-distribution grids grouped by JetEta category using PyROOT."
    )

    parser.add_argument(
        "rootfile",
        help="Input ROOT file, e.g. ClosureVsRefPt.root",
    )

    parser.add_argument(
        "--alg",
        default=None,
        help="Algorithm directory, e.g. ak4pfpuppiHLT. If omitted, use first directory.",
    )

    parser.add_argument(
        "--histdir",
        default="RelRspHistograms",
        help="Histogram subdirectory inside the algorithm directory.",
    )

    parser.add_argument(
        "-o",
        "--outdir",
        default="response_grids_by_eta",
        help="Output directory.",
    )

    parser.add_argument(
        "--normalize",
        action="store_true",
        help="Normalize each response histogram to unit area.",
    )

    parser.add_argument(
        "--logy",
        action="store_true",
        help="Use logarithmic y-axis.",
    )

    parser.add_argument(
        "--xmin",
        type=float,
        default=0.0,
        help="Minimum x-axis value.",
    )

    parser.add_argument(
        "--xmax",
        type=float,
        default=2.0,
        help="Maximum x-axis value, e.g. --xmax 3.0.",
    )

    parser.add_argument(
        "--out-ext",
        default="png",
        choices=["png", "pdf", "eps", "root"],
        help="Output file extension.",
    )

    args = parser.parse_args()

    f = ROOT.TFile.Open(args.rootfile)
    if not f or f.IsZombie():
        raise RuntimeError(f"Could not open ROOT file: {args.rootfile}")

    # Pick algorithm directory
    if args.alg is None:
        alg = None
        keys = f.GetListOfKeys()
        for key in keys:
            obj = key.ReadObj()
            if obj.InheritsFrom("TDirectory"):
                alg = key.GetName()
                break

        if alg is None:
            raise RuntimeError("No algorithm directories found in ROOT file.")

        print(f"No --alg given. Using first directory: {alg}")
    else:
        alg = args.alg

    alg_dir = f.Get(alg)
    if not alg_dir:
        raise RuntimeError(f"Could not find algorithm directory '{alg}' in {args.rootfile}")

    hdir_path = f"{alg}/{args.histdir}"
    hdir = f.Get(hdir_path)
    if not hdir:
        raise RuntimeError(
            f"Could not find directory '{hdir_path}' in {args.rootfile}. "
            f"Check --alg and --histdir."
        )

    grouped = defaultdict(list)

    for key in hdir.GetListOfKeys():
        name = key.GetName()

        match = RESPONSE_RE.match(name)
        if not match:
            continue

        hist = hdir.Get(name)
        if not hist:
            continue

        eta_key = "JetEta" + match.group("eta")

        grouped[eta_key].append(
            {
                "idx": int(match.group("idx")),
                "ptmin": match.group("ptmin"),
                "ptmax": match.group("ptmax"),
                "hist": hist,
            }
        )

    if not grouped:
        raise RuntimeError(
            f"No Response_JetEta..._RefPt... histograms found in {hdir_path}."
        )

    print(f"Found {len(grouped)} eta categories:")
    for eta_key in sorted(grouped.keys()):
        print(f"  {eta_key}: {len(grouped[eta_key])} pT bins")

    for eta_key in sorted(grouped.keys()):
        make_grid_for_eta(
            eta_key=eta_key,
            entries=grouped[eta_key],
            outdir=args.outdir,
            alg=alg,
            normalize=args.normalize,
            logy=args.logy,
            out_ext=args.out_ext,
            xmin=args.xmin,
            xmax=args.xmax,
        )

    f.Close()


if __name__ == "__main__":
    main()