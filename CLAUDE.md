# Claude Code Configuration — AIACA-R

Instructions for Claude working in this repository.

## 1. Project

This repository is the companion workbook to *AI-Assisted Content Analysis*, a book for Sage by Seraphine F. Maerz and Kenneth Benoit. It is a Quarto website with the full worked examples of the book's chapters, the R code behind them, the data, and exercises. The code is built on the authors' R package `quallmer`.

The book's source is in a separate, private repository, `quallmer/AIACA`. The book states the methodology and stays independent of software. Code belongs here.

**This repository is public.** Everything committed, including rendered output stored in `_freeze/`, can be read by anyone.

## 2. How this differs from the book repository

The book repository has rules for reading notes, decision registers, and a log of AI-drafted passages. **None of them applies here.** The authors have Sage's permission for this website to be written primarily with Claude, and they will edit it heavily.

- Write and revise pages and code directly when an author asks.
- Keep no notes files, decision registers, or drafting logs in this repository.
- Do not add notices to pages or code about who or what wrote them, or about what an author has yet to check.
- An author still decides what an example shows and claims. Where a page states a result, the figure comes from code on that page, and a limit of the evidence is stated as a limit.

## 3. Rights in the source material

Some source material may not be redistributed, and this repository is public.

- Never commit source texts, expert scoring transcribed from a source, or model output that quotes source text, unless the [data page](data.qmd) records that the terms allow it.
- Each chapter's `data/` folder is git-ignored. Restricted files live there, or in a folder outside the repository that an environment variable names.
- Rendered pages and `_freeze/` are public too. A chunk must not print restricted text. Show counts, agreement figures, and identifiers. Before committing `_freeze/`, search it for source text.
- When a new dataset is used, add it to `data.qmd` with its source, its terms, and how a reader obtains it.

## 4. Layout

```
_quarto.yml              site configuration; the sidebar follows the book's parts and chapters
index.qmd                home page, with the table of chapters
getting-started.qmd      installing R and quallmer, API keys
data.qmd                 every dataset: source, terms, how it is obtained
styles.scss              small additions to the cosmo theme
chNN-short-name/         one folder for each chapter of the book that has material
  index.qmd              the example at a glance: question, design, results
  NN-short-name.qmd      one tutorial page for each step, numbered in order
  exercises.qmd          exercises with folded solutions
  R/setup.R              packages, models, and helpers shared by the chapter's pages
  codebook/              the coding specification, one file for each version
  get-data.R             downloads material that cannot be redistributed
  data/                  git-ignored: source files and saved model runs
_templates/              page templates; not rendered
tools/make-downloads.R   post-render: a script for each page, an archive for each chapter
_freeze/                 stored results of executed pages; committed
_site/                   rendered site; git-ignored
```

A chapter folder takes the number and short name of the chapter's file in the book repository (`04-foundations-research-design.qmd` becomes `ch04-research-design/`).

## 5. Tutorial pages

- **Code is embedded in the page.** A tutorial is a `.qmd` page of prose and executed R chunks, not a script with a description beside it. Start from `_templates/tutorial-page.qmd`. Readers download a page's code as a script, which `tools/make-downloads.R` extracts after each render.
- **Paths are relative to the chapter folder**, where Quarto runs each page. Pages begin with `source("R/setup.R")`.
- **Data location.** `R/setup.R` sets the folder that holds source files and saved runs: `data/` beside the pages, or the folder an environment variable names (for Chapter 4, `AIACA_CH04_DATA`).
- **A model request is made once.** Wrap it so that the output is saved on the first run and read back afterwards (the `run_once()` pattern). A chunk that would always make a request is set to `eval: false`.
- **Rendering makes no request.** Results are frozen (`freeze: auto`) and `_freeze/` is committed, so the site builds with no API key and without the data. When checking a render, blank the keys so that an unsaved run fails instead of spending money.
- **Rendering must not change shared data.** If a page writes files, render against a private copy of the data folder.
- **Add each new page to the sidebar** in `_quarto.yml`, and update the chapter's row in the table on `index.qmd`.

## 6. Code style

- As simple as possible: short, linear code a reader can follow, in tidyverse style, formatted with `air`.
- Use `quallmer`'s own functions for the work: `qlm_code()` to code, `qlm_replicate()` and `qlm_compare()` for stability and a second coder, `as_qlm_coded()` to bring in human labels, `qlm_validate()` against a gold standard. Check the package's help pages for current signatures.
- Reach for a `quallmer` function before writing a helper. Do not build provenance or guard machinery around runs.
- Model names, versions, prices, and settings belong here, not in the book. State the model and the date of each run.

## 7. Prose style

- UK spelling, the serial comma, and "judgment" without an "e".
- Plain and direct. The first person plural is fine here.
- Use the book's terminology: LLM for the model coding text, coder, coding scheme, coding specification, inter-coder reliability, validation. Do not write "the AI" for the coder.
- Package and function names in monospace: `quallmer`, `qlm_code()`. Languages and applications in ordinary type: R, Python, RStudio.
- Avoid the acronym "AIACA" in prose. It is a repository name.
- Headings in title case.

## 8. Build

```bash
quarto preview        # live preview
quarto render         # the whole site, into _site/
```

`_site/` is git-ignored. Do not edit it.

## 9. Git

- Default branch: `main`. Work on a topic branch and open a pull request for anything non-trivial.
- Do not push to `main`, and do not publish the site, without an author's explicit confirmation.
- Commit messages in the imperative mood, scoped where useful (`ch04: add the pilot page`).
- Commits and pull requests go out in the authors' names. Add no AI attribution lines.
