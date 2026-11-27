# Step 13, second part. The expert scoring of practice Sets G to J.
#
# The manual prints the expert scoring of its practice sets on pages of their
# own. For Sets G to J those pages were opened only after both coders' output
# on these sets was saved. The scoring was transcribed twice and
# independently, as one record for each margin label: its motive, the phrases
# the expert underlines, and the remark beside it. The two entries agree on
# every image.
#
# This script places each image in the sentences it may be scored in. An
# image can have more than one admissible sentence: the expert marks one image
# across several phrases, names another phrase that could be scored instead,
# or says the next or the previous sentence would do. In two places the
# expert marks neighbouring sentences separately and notes that only one of
# each pair is scored; those labels are one image (`group`).

source("R/setup.R")

transcription <- read_csv(
  file.path(runs_dir, "practice_GJ_key_transcription.csv"),
  show_col_types = FALSE
) |>
  mutate(
    label = row_number(),
    image = consecutive_id(coalesce(group, as.character(label))),
    .by = doc
  )

sentences <- read_practice_sets() |>
  select(doc, sentence, text)
text_of <- function(doc) sentences$text[sentences$doc == doc]

# The underlined phrases, in the order printed.
phrases <- transcription |>
  separate_longer_delim(phrases, " | ") |>
  mutate(sentence = locate_phrases(phrases, text_of(doc[1])), .by = doc)

# Where two labels of one group underline the same word, the second label's
# word is its next occurrence, in a later sentence.
next_occurrence <- function(phrase, doc, after) {
  hits <- str_which(plain(text_of(doc)), str_c("\\b", plain(phrase), "\\b"))
  first(hits[hits > after])
}
phrases <- phrases |>
  mutate(
    repeated = !is.na(group) & duplicated(str_c(group, phrases)),
    .by = doc
  ) |>
  mutate(
    sentence = if_else(
      repeated,
      pmap_int(list(phrases, doc, sentence), next_occurrence),
      sentence
    )
  ) |>
  select(-repeated)

# Every phrase has to be found. A phrase that is not is a slip in the
# transcription of the scoring or of the text, to be looked up on the page.
filter(phrases, is.na(sentence))

# A phrase the remark names but the expert did not underline: the sentence
# with that phrase nearest to the image's own.
nearest_with <- function(phrase, doc, near) {
  hits <- str_which(plain(text_of(doc)), str_c("\\b", plain(phrase), "\\b"))
  if (length(hits)) hits[which.min(abs(hits - near))] else NA_integer_
}

key <- phrases |>
  summarise(
    own = list(sort(unique(sentence))),
    also_next = any(also_next),
    also_previous = any(also_previous),
    extra = first(na.omit(extra)),
    remark = str_flatten(unique(na.omit(remark)), "; "),
    phrases = str_flatten(phrases, " | "),
    .by = c(doc, image, motive)
  ) |>
  mutate(
    sentences = pmap(
      list(own, also_next, also_previous, extra, doc),
      \(own, also_next, also_previous, extra, doc) {
        last_sentence <- length(text_of(doc))
        admissible <- c(
          own,
          if (also_next) max(own) + 1,
          if (also_previous) min(own) - 1,
          if (!is.na(extra)) nearest_with(extra, doc, own[1])
        )
        sort(unique(admissible[admissible >= 1 & admissible <= last_sentence]))
      }
    )
  ) |>
  select(doc, image, motive, remark, sentences, phrases)

# An extra phrase that was not found.
transcription |>
  filter(!is.na(extra)) |>
  mutate(
    found = map2_int(extra, doc, \(extra, doc) nearest_with(extra, doc, 1))
  )

key |>
  mutate(sentences = map_chr(sentences, str_flatten, "|")) |>
  write_csv(file.path(runs_dir, "practice_GJ_key.csv"))

# Scored images by set and motive.
key |>
  count(set = str_remove(doc, "[0-9]+$"), motive) |>
  pivot_wider(names_from = motive, values_from = n)

# Images with more than one admissible sentence.
key |>
  count(admissible_sentences = lengths(sentences))
