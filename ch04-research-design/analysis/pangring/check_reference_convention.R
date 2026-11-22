#!/usr/bin/env Rscript

# Do sentence-level motive labels look as if they were scored under Winter's
# counting convention for consecutive sentences?
#
# The convention, as recorded in KB's reading note on Winter (1994, pp. 21, 31):
# imagery for the same motive in two consecutive sentences is scored once; a
# third consecutive sentence can be scored again; and both of two consecutive
# sentences may be scored where imagery for another motive intervenes.
#
# If labels follow the convention, two adjacent positives for the same motive
# should occur only where another motive is also scored, and the pattern
# scored / unscored / scored should be more common than chance. If labels record
# imagery presence, adjacent positives with no other motive should be common,
# because imagery clusters.
#
# This is a private diagnostic on reference labels only. It runs no model, writes
# no file, and does not settle who coded the material or under which
# instructions. That comes from the published account.
#
# Usage:
#   Rscript analysis/pangring/check_reference_convention.R FILE [DOC_COLUMNS] [MOTIVE_COLUMNS]
#
#   FILE            .xlsx (first sheet) or .csv, one row per sentence
#   DOC_COLUMNS     comma-separated columns that together identify a document.
#                   Default: Person,Filename if both exist, otherwise Subj_story.
#   MOTIVE_COLUMNS  comma-separated label columns. Default: Pow,Ach,Aff.
#
# Examples:
#   Rscript analysis/pangring/check_reference_convention.R UD1_sentences.xlsx Subj_story
#   Rscript analysis/pangring/check_reference_convention.R UD2_sentences.xlsx Person,Filename
#
# Assumption that the script cannot check: rows are in sentence order within
# each document.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
    stop("Supply the path to the sentence file. See the header for usage.",
         call. = FALSE)
}
path <- args[1]
split_arg <- function(x) trimws(strsplit(x, ",", fixed = TRUE)[[1]])
doc_cols <- if (length(args) >= 2) split_arg(args[2]) else NULL
motive_cols <- if (length(args) >= 3) split_arg(args[3]) else c("Pow", "Ach", "Aff")
text_col <- "Text"

# ---- read -------------------------------------------------------------------

if (grepl("\\.xlsx?$", path, ignore.case = TRUE)) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
        stop("Install the readxl package to read Excel files.", call. = FALSE)
    }
    sheets <- readxl::excel_sheets(path)
    if (length(sheets) > 1) {
        cat("Sheets:", paste(sheets, collapse = ", "), "- reading the first.\n")
    }
    dat <- as.data.frame(readxl::read_excel(path, sheet = 1),
                         stringsAsFactors = FALSE)
} else {
    dat <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

cat("File:   ", basename(path), "\n")
cat("Columns:", paste(names(dat), collapse = ", "), "\n")
cat("Rows:   ", nrow(dat), "\n")

if (is.null(doc_cols)) {
    doc_cols <- if (all(c("Person", "Filename") %in% names(dat))) {
        c("Person", "Filename")
    } else {
        "Subj_story"
    }
    cat("Document key not supplied; using:", paste(doc_cols, collapse = " + "),
        "\n  Check that this identifies one story or one email.\n")
}

missing_cols <- setdiff(c(text_col, doc_cols, motive_cols), names(dat))
if (length(missing_cols) > 0) {
    stop("Columns not found: ", paste(missing_cols, collapse = ", "),
         ". Pass the document and motive columns as arguments.", call. = FALSE)
}

# ---- rows and documents -----------------------------------------------------

has_text <- !is.na(dat[[text_col]]) & nzchar(trimws(as.character(dat[[text_col]])))
cat("Rows with text:", sum(has_text), "\n")
if (any(!has_text)) {
    cat("Rows without text:", sum(!has_text), "at row(s)",
        paste(head(which(!has_text), 10), collapse = ", "),
        if (sum(!has_text) > 10) "..." else "", "\n",
        " These are dropped. Sentences either side of one are then treated as adjacent.\n")
}
dat <- dat[has_text, , drop = FALSE]
n <- nrow(dat)

key <- do.call(paste, c(lapply(dat[doc_cols], as.character), sep = " | "))
if (anyNA(dat[doc_cols])) {
    cat("Warning: missing values in the document key columns.\n")
}

# Documents are taken as unbroken blocks of the key in file order, because file
# order is the only evidence of sentence order.
new_block <- c(TRUE, key[-1] != key[-n])
block <- cumsum(new_block)
n_blocks <- max(block)
n_keys <- length(unique(key))
cat("Documents (distinct keys):", n_keys, "\n")
if (n_blocks > n_keys) {
    cat("Warning:", n_blocks - n_keys, "more unbroken blocks than distinct keys.",
        "Some keys recur after other documents,\n  so the key does not identify",
        "a document or the rows are not in document order.\n",
        " Adjacency below uses unbroken blocks.\n")
}
doc_len <- tabulate(block, n_blocks)
cat("Sentences per document: min", min(doc_len), " median", median(doc_len),
    " max", max(doc_len), "\n")
cat("Single-sentence documents:", sum(doc_len == 1), "\n")

# ---- labels -----------------------------------------------------------------

cat("\nLabel values\n")
positive <- matrix(FALSE, nrow = n, ncol = length(motive_cols),
                   dimnames = list(NULL, motive_cols))
for (m in motive_cols) {
    raw <- dat[[m]]
    num <- suppressWarnings(as.numeric(as.character(raw)))
    tab <- table(raw, useNA = "ifany")
    cat(sprintf("  %-5s", m),
        paste(sprintf("%s: %d", ifelse(is.na(names(tab)), "NA", names(tab)), tab),
              collapse = "   "), "\n")
    if (any(is.na(num) & !is.na(raw))) {
        cat("        non-numeric values are treated as not scored\n")
    }
    if (any(num > 1, na.rm = TRUE)) {
        cat("        values above 1 occur: a sentence can carry more than one",
            "score. Positive here means above 0.\n")
    }
    positive[, m] <- !is.na(num) & num > 0
}

# ---- adjacency --------------------------------------------------------------

same_next <- block[-1] == block[-n]                 # row i and i + 1, same document
same_next2 <- if (n >= 3) block[-(1:2)] == block[-((n - 1):n)] else logical(0)

audit_motive <- function(m) {
    pos <- positive[, m]
    other <- rowSums(positive[, setdiff(motive_cols, m), drop = FALSE]) > 0

    k <- as.numeric(tapply(pos, block, sum))
    len <- as.numeric(doc_len)

    pair <- pos[-n] & pos[-1] & same_next
    pair_other <- pair & (other[-n] | other[-1])
    exp_pair <- sum(k * (k - 1) / len)

    gap <- if (n >= 3) {
        pos[-((n - 1):n)] & !pos[-c(1, n)] & pos[-(1:2)] & same_next2
    } else {
        logical(0)
    }
    ok <- len >= 3
    exp_gap <- sum(k[ok] * (k[ok] - 1) * (len[ok] - k[ok]) /
                       (len[ok] * (len[ok] - 1)))

    # Runs of consecutive positives, broken at document boundaries.
    run_id <- cumsum(c(TRUE, pos[-1] != pos[-n] | !same_next))
    run_len <- tabulate(run_id)[unique(run_id[pos])]

    ratio <- function(obs, expd) if (expd > 0) sprintf("%.2f", obs / expd) else "n/a"

    cat("\n", m, "\n", sep = "")
    cat(sprintf("  Positive sentences:              %d of %d (%.1f%%)\n",
                sum(pos), n, 100 * mean(pos)))
    cat(sprintf("  Documents with a positive:       %d of %d\n",
                sum(k > 0), n_blocks))
    cat(sprintf("  Adjacent positive pairs:         %d observed, %.1f expected if positions were random (ratio %s)\n",
                sum(pair), exp_pair, ratio(sum(pair), exp_pair)))
    cat(sprintf("    no other motive in either:     %d   <- the convention does not allow these\n",
                sum(pair) - sum(pair_other)))
    cat(sprintf("    another motive in either:      %d   <- may fall under the exception\n",
                sum(pair_other)))
    cat(sprintf("  Scored / unscored / scored:      %d observed, %.1f expected if positions were random (ratio %s)\n",
                sum(gap), exp_gap, ratio(sum(gap), exp_gap)))
    if (length(run_len) > 0) {
        rt <- table(run_len)
        cat("  Runs of consecutive positives:   ",
            paste(sprintf("length %s: %d", names(rt), rt), collapse = "   "), "\n")
    }
    invisible(NULL)
}

for (m in motive_cols) audit_motive(m)

# ---- how to read it ---------------------------------------------------------

cat("
Reading the output
  'Expected if positions were random' shuffles each document's positives among
  its own sentences. It is a benchmark, not a model of how imagery is written,
  and a ratio built on an expected count below about 20 is too noisy to read.

  The line to read first is 'no other motive in either'. These are the pairs
  the convention rules out.
  Consistent with the consecutive-sentence convention:
    that count at or near zero, and scored / unscored / scored above
    expectation, because a run of three imagery sentences is scored 1, 0, 1.
  Consistent with imagery presence coded sentence by sentence:
    that count large, adjacent pairs at or above expectation, and
    scored / unscored / scored below expectation.
  Anything between needs the published account of how the labels were made.
  The ratio for adjacent pairs is not decisive by itself: pairs allowed by the
  exception can bring it close to 1 even where the convention was applied.

  'Another motive in either' approximates the intervening-motive exception. The
  labels show that another motive was scored in one of the two sentences, not
  that its imagery fell between the two occurrences.
")
