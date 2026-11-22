# Shared setup for the motive-imagery worked example (Chapter 4).
#
# Every page and script sources this file. Run them from the chapter's folder.

library(quallmer)
library(tidyverse)
library(readxl)

# The source files and the saved model runs are in `data/` beside the pages,
# or in the folder that AIACA_CH04_DATA names.
data_dir <- Sys.getenv("AIACA_CH04_DATA", "data")
stopifnot(dir.exists(data_dir))
runs_dir <- file.path(data_dir, "runs")

# The coding specification: `motive_codebook`, `make_motive_input()`,
# `apply_counting_convention()`, and `category_agreement()`.
source("codebook/motive_codebook_v0.3.R")

# The coders. Every setting not given here is left at the provider's default.
models <- c(
  main = "anthropic/claude-sonnet-5-5",
  second = "deepseek/deepseek-flash"
)
max_tokens <- 64000

motives <- c("ach", "aff", "pow")

# Data ------------------------------------------------------------------------

# Which documents are for development and which are reserved (01_partition.R).
read_partition <- function() {
  read_csv(file.path(runs_dir, "partition.csv"), show_col_types = FALSE)
}

# Winter's practice and calibration stories, one row per sentence, in Pang and
# Ring's transcription. `labels = TRUE` adds the expert's labels for the
# development stories only. The labels of a reserved story are never returned.
read_stories <- function(labels = FALSE) {
  roles <- read_partition() |> select(doc = unit, role)
  stories <- read_excel(file.path(data_dir, "UD1_sentences.xlsx")) |>
    transmute(
      doc = Subj_story,
      set = str_remove(doc, "[0-9]+$"),
      cue = Story_name,
      text = Text,
      ach = Ach > 0,
      aff = Aff > 0,
      pow = Pow > 0
    ) |>
    mutate(sentence = row_number(), .by = doc, .after = cue) |>
    left_join(roles, by = "doc") |>
    mutate(.id = str_c(doc, sentence, sep = ":"), .before = 1)
  if (labels) {
    mutate(
      stories,
      across(all_of(motives), \(x) if_else(role == "development", x, NA))
    )
  } else {
    select(stories, -all_of(motives))
  }
}

# Pang and Ring's email sentences, one row per sentence. A document is one
# email of one writer. `labels = TRUE` is used only with the first-test
# emails, from 07_validate_emails.R onwards. No script reads the labels of the
# hold-out.
read_emails <- function(labels = FALSE) {
  roles <- read_partition() |> select(writer = unit, role)
  emails <- read_excel(file.path(data_dir, "UD2_sentences.xlsx")) |>
    filter(!is.na(Text), str_squish(Text) != "") |>
    transmute(
      writer = Person,
      doc = str_c(Person, Filename, sep = "/"),
      text = Text,
      ach = Ach > 0,
      aff = Aff > 0,
      pow = Pow > 0
    ) |>
    mutate(sentence = row_number(), .by = doc, .after = doc) |>
    left_join(roles, by = "writer") |>
    mutate(.id = str_c(doc, sentence, sep = ":"), .before = 1)
  if (labels) emails else select(emails, -all_of(motives))
}

# Calibration Set B, a speech printed in the manual (01b_calibration_b.R).
read_speech <- function() {
  read_csv(
    file.path(runs_dir, "calibration_b_sentences.csv"),
    show_col_types = FALSE
  ) |>
    transmute(
      .id = str_c("CB", sentence, sep = ":"),
      doc = "CB",
      sentence,
      text
    )
}

# The manual's practice Sets G to J (01c_practice_sets.R): 30 stories told in
# an interview, of which only the subject's sentences are kept, and three
# political speeches. Reserved as a fresh test. Their expert scoring is not
# in any file the scripts read.
read_practice_sets <- function() {
  read_csv(
    file.path(runs_dir, "practice_GJ_sentences.csv"),
    show_col_types = FALSE
  ) |>
    transmute(
      .id = str_c(doc, sentence, sep = ":"),
      doc,
      set,
      turn,
      sentence,
      text
    )
}

# Coding ----------------------------------------------------------------------

# The codebook of another version, without disturbing the frozen one loaded
# above.
codebook_of <- function(version) {
  file <- str_c("codebook/motive_codebook_", version, ".R")
  version_objects <- new.env()
  sys.source(file, envir = version_objects)
  version_objects$motive_codebook
}

# One input per document: its sentences, numbered, in the form the
# specification asks for.
document_inputs <- function(sentences) {
  sentences |>
    summarise(input = make_motive_input(text), .by = doc) |>
    deframe()
}

# A run is made once and saved. After that it is read back, never repeated.
run_once <- function(label, run) {
  path <- file.path(runs_dir, label, "coded.rds")
  if (!file.exists(path)) {
    dir.create(dirname(path), showWarnings = FALSE)
    saveRDS(run, path)
  }
  readRDS(path)
}

# A saved run, by the name of its folder.
read_run <- function(label) readRDS(file.path(runs_dir, label, "coded.rds"))

# The images a run lists, one row per image.
image_list <- function(coded) {
  coded |>
    as_tibble() |>
    select(doc = .id, sentences) |>
    unnest(sentences) |>
    select(doc, sentence = id, images) |>
    unnest(images) |>
    mutate(across(c(motive, criterion), as.character)) |>
    mutate(order = row_number(), .by = c(doc, sentence), .after = sentence)
}

# The images that count towards a score, after the manual's counting rule.
scored_images <- function(coded) {
  coded |>
    image_list() |>
    apply_counting_convention() |>
    filter(scored) |>
    select(doc, sentence, motive)
}

# The same run with one row per sentence: is each motive listed in it? This is
# the form that `qlm_compare()` and `qlm_validate()` take.
sentence_codes <- function(coded, name) {
  coded |>
    as_tibble() |>
    select(doc = .id, sentences) |>
    unnest(sentences) |>
    transmute(
      .id = str_c(doc, id, sep = ":"),
      ach = map_lgl(images, \(x) "ACH" %in% x$motive),
      aff = map_lgl(images, \(x) "AFF" %in% x$motive),
      pow = map_lgl(images, \(x) "POW" %in% x$motive)
    ) |>
    distinct(.id, .keep_all = TRUE) |>
    as_qlm_coded(name = name)
}

# Labels in the same form, as the gold standard.
gold_codes <- function(labels, name) {
  labels |>
    select(.id, all_of(motives)) |>
    as_qlm_coded(name = name, is_gold = TRUE)
}

# Precision, recall, and F1 for the presence of each motive, one row per coder
# and motive. F1 for presence is the manual's category agreement.
presence_measures <- function(validation) {
  validation |>
    as_tibble() |>
    filter(class == "TRUE") |>
    select(rater, variable, measure, value) |>
    pivot_wider(names_from = measure, values_from = value)
}

# Placing the expert's phrases in sentences -------------------------------------

# Lower case, letters and digits only, so that punctuation and spacing do not
# matter when a phrase is looked for in a text.
plain <- function(x) {
  x |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", " ") |>
    str_squish()
}

# The sentence of one document that holds each phrase. `text` is the
# document's sentences in order. Phrases come in the order they are printed,
# so each is looked for from the sentence of the one before it. That settles
# a short phrase such as "best" that occurs twice.
locate_phrases <- function(phrase, text) {
  text <- plain(text)
  found <- integer(length(phrase))
  from <- 1
  for (i in seq_along(phrase)) {
    hit <- str_which(text, str_c("\\b", plain(phrase[i]), "\\b"))
    # a transcription corrects a misspelling here and there
    if (!length(hit)) {
      hit <- agrep(plain(phrase[i]), text, max.distance = 0.1)
    }
    found[i] <- first(hit[hit >= from])
    if (!is.na(found[i])) {
      from <- found[i]
    } else if (length(hit)) {
      # a phrase printed again for a second label: the occurrence just before
      found[i] <- last(hit)
    }
  }
  found
}

# The calibration key ----------------------------------------------------------

# The expert scoring of the calibration sets (06b_calibration_key.R): one row
# for each image, with the first and last sentence it may be scored in.
read_key <- function() {
  read_csv(
    file.path(runs_dir, "calibration_key.csv"),
    show_col_types = FALSE
  ) |>
    mutate(
      set = str_remove(doc, "[0-9]+$"),
      first = parse_number(str_extract(sentences, "^[0-9]+")),
      last = parse_number(str_extract(sentences, "[0-9]+$"))
    )
}

# The number of the expert's images that a coder's images agree with, in one
# document and for one motive. `first` and `last` bound the sentences each
# expert image may be scored in. `tolerance = 1` also accepts the sentence on
# either side, as the manual does for a pair of adjacent sentences (p. 31).
agreements <- function(sentence, first, last, tolerance = 0) {
  sentence <- sort(sentence)
  used <- rep(FALSE, length(sentence))
  for (i in order(last)) {
    hit <- which(
      !used & sentence >= first[i] - tolerance & sentence <= last[i] + tolerance
    )
    used[hit[1]] <- TRUE
  }
  sum(used)
}

# The manual's category agreement with the key, for each coder, set, and
# motive: twice the agreements over the coder's images plus the expert's.
# `coders` has one row per scored image: coder, doc, sentence, motive.
agreement_with_key <- function(coders, key, tolerance = 0) {
  coders |>
    nest(coder_images = sentence) |>
    full_join(
      nest(key, expert_images = c(first, last), .by = c(doc, motive)) |>
        cross_join(distinct(coders, coder)),
      by = c("coder", "doc", "motive")
    ) |>
    mutate(
      set = str_remove(doc, "[0-9]+$"),
      n_coder = map_int(coder_images, \(x) if (is.null(x)) 0L else nrow(x)),
      n_expert = map_int(expert_images, \(x) if (is.null(x)) 0L else nrow(x)),
      n_agree = map2_int(coder_images, expert_images, \(x, y) {
        if (is.null(x) || is.null(y)) {
          return(0L)
        }
        agreements(x$sentence, y$first, y$last, tolerance)
      })
    ) |>
    summarise(
      agreements = sum(n_agree),
      coder_images = sum(n_coder),
      expert_images = sum(n_expert),
      .by = c(set, coder, motive)
    ) |>
    mutate(
      tolerance = tolerance,
      category_agreement = 2 * agreements / (coder_images + expert_images)
    ) |>
    arrange(set, motive, coder)
}

# Dictionary -------------------------------------------------------------------

# The six General Inquirer categories named in the 1966 account of scoring
# achievement imagery by computer. Word senses are ignored.
inquirer_categories <- c("Goal", "Try", "Means", "Persist", "Complet", "Fail")

read_inquirer <- function() {
  inquirer <- read_csv(
    "analysis/geninquirer/inquireraugmented.csv",
    col_types = cols(.default = "c")
  ) |>
    slice(-1) |>
    mutate(word = str_to_lower(str_remove(Entry, "#.*$")))
  map(set_names(inquirer_categories), \(category) {
    unique(inquirer$word[!is.na(inquirer[[category]])])
  })
}

# The number of words of each category in each text, matched on stems or on
# exact forms.
category_counts <- function(text, stem = TRUE) {
  words <- read_inquirer()
  toks <- quanteda::tokens(
    str_to_lower(text),
    remove_punct = TRUE,
    remove_symbols = TRUE,
    remove_numbers = TRUE
  )
  if (stem) {
    toks <- quanteda::tokens_wordstem(toks)
    words <- map(words, \(w) unique(quanteda::char_wordstem(w)))
  }
  quanteda::dfm(toks) |>
    quanteda::dfm_lookup(quanteda::dictionary(words), valuetype = "fixed") |>
    quanteda::convert(to = "data.frame") |>
    as_tibble() |>
    select(-doc_id)
}
