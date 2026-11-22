# AI-Assisted Content Analysis: Companion Workbook

The companion workbook to *AI-Assisted Content Analysis*, by Seraphine F. Maerz and Kenneth Benoit (Sage, forthcoming). It is a [Quarto](https://quarto.org) website with the full worked examples of the book's chapters, the R code behind them, the data, and exercises. The code uses the authors' R package [`quallmer`](https://quallmer.github.io/quallmer/).

The workbook is a draft and is being written alongside the book.

## Contents

- `index.qmd`, `getting-started.qmd`, `data.qmd`: the home page, setup instructions, and the catalogue of datasets.
- `chNN-short-name/`: one folder for each chapter of the book that has companion material, with its tutorial pages, shared code, coding specification, and exercises.
- `_templates/`: templates for a tutorial page and an exercises page.
- `tools/`: scripts used when the site is built.

## Building the site

With Quarto and R installed:

```bash
quarto render
```

The site is written to `_site/`. Results of executed code are stored in `_freeze/`, so the site builds without an API key and without the source data.

## Data

Some of the material the examples use cannot be redistributed. `data.qmd` lists each dataset with its source and terms, and each chapter's `get-data.R` downloads what the workbook does not include.

## Licence

To be decided.
