# Step 10. The LLM coders beside the human benchmarks.
#
# Two questions. Do the LLM coders agree with the expert as well as a trained
# human scorer must? Do they agree with each other as well as human coders do?
#
# No text in our material was scored by two human coders, and no independent
# human scored the calibration sets. The human side is therefore what the
# sources publish, and cannot be recomputed here:
#   - the manual: a scorer must reach a category agreement of .85 with the
#     expert on each motive;
#   - Pang and Ring (2020, p. 555): three coders on 30 stories;
#   - Pang and Ring (2020, p. 557): the two coders of the emails, on 393
#     picture stories.
# Pang and Ring report the intraclass correlation of story-level motive
# scores: two-way, consistency, average rating, which is ICC(3,k).
#
# The LLM figures are for the frozen v0.3. Calibration Set A was untouched
# when it was coded. The practice stories are development material.

source("R/setup.R")

human <- tribble(
  ~benchmark                                , ~ach , ~aff , ~pow ,
  "Three human coders, 30 stories (p. 555)" , 0.90 , 0.96 , 0.83 ,
  "Two human coders, 393 stories (p. 557)"  , 0.85 , 0.78 , 0.84
)

# Story-level scores -----------------------------------------------------------

# The number of scored images of each motive in each story, as a coded object.
story_scores <- function(images, docs, name) {
  images |>
    count(doc, motive) |>
    complete(doc = docs, motive = str_to_upper(motives), fill = list(n = 0L)) |>
    mutate(motive = str_to_lower(motive)) |>
    pivot_wider(names_from = motive, values_from = n) |>
    rename(.id = doc) |>
    as_qlm_coded(name = name)
}

calibration_stories <- read_stories() |>
  filter(set == "CA") |>
  distinct(doc) |>
  pull(doc)

expert <- read_key() |>
  filter(set == "CA") |>
  story_scores(calibration_stories, "expert")
main <- read_run("reserved_CA_claude-sonnet-5-5") |>
  scored_images() |>
  story_scores(calibration_stories, "main")
again <- read_run("reserved_CA_claude-sonnet-5-5_r2") |>
  scored_images() |>
  story_scores(calibration_stories, "repeat")
second <- read_run("reserved_CA_deepseek-flash") |>
  scored_images() |>
  story_scores(calibration_stories, "second")

# What `qlm_compare()` reports for scores: Krippendorff's alpha, the
# single-rater ICC for absolute agreement, and Pearson's r.
qlm_compare(main, expert, level = "interval", ci = "analytic")
qlm_compare(second, expert, level = "interval", ci = "analytic")
qlm_compare(main, second, level = "interval", ci = "analytic")
qlm_compare(main, again, level = "interval", ci = "analytic")

# The form Pang and Ring report, for two coders: consistency of the two
# scores, stepped up to the reliability of their average.
icc_average <- function(x, y) {
  single <- 2 * cov(x, y) / (var(x) + var(y))
  2 * single / (1 + single)
}

icc_by_motive <- function(a, b, benchmark) {
  a <- as_tibble(a)
  b <- as_tibble(b)
  stopifnot(identical(a$.id, b$.id))
  tibble(
    benchmark,
    ach = icc_average(a$ach, b$ach),
    aff = icc_average(a$aff, b$aff),
    pow = icc_average(a$pow, b$pow)
  )
}

# The same pair of LLM coders on the 180 practice stories.
practice_stories <- read_stories() |>
  filter(role == "development") |>
  distinct(doc) |>
  pull(doc)
practice_main <- read_run("pilot_v0.3_claude-sonnet-5-5") |>
  scored_images() |>
  story_scores(practice_stories, "main")
practice_second <- read_run("pilot_v0.3_deepseek-flash") |>
  scored_images() |>
  story_scores(practice_stories, "second")

bind_rows(
  human,
  icc_by_motive(main, second, "Main and second LLM coder, Set A"),
  icc_by_motive(
    practice_main,
    practice_second,
    "Main and second LLM coder, practice stories"
  ),
  icc_by_motive(main, again, "Main LLM coder and its repeat, Set A"),
  icc_by_motive(main, expert, "Main LLM coder and the expert, Set A"),
  icc_by_motive(second, expert, "Second LLM coder and the expert, Set A")
)

# The manual's index -----------------------------------------------------------

# Against the expert, all three motives together, in the key's sentences and
# with the adjacent sentence allowed. The standard for a human scorer is .85.
coders <- bind_rows(
  main = scored_images(read_run("reserved_CA_claude-sonnet-5-5")),
  second = scored_images(read_run("reserved_CA_deepseek-flash")),
  .id = "coder"
)
key <- filter(read_key(), set == "CA")

bind_rows(
  agreement_with_key(coders, key, tolerance = 0),
  agreement_with_key(coders, key, tolerance = 1)
) |>
  summarise(
    category_agreement = 2 *
      sum(agreements) /
      (sum(coder_images) + sum(expert_images)),
    .by = c(coder, tolerance)
  )

# Between the two LLM coders, the same index. Pang and Ring say pairs of human
# coders are held to .85 on it (p. 550).
category_agreement(
  filter(coders, coder == "main"),
  filter(coders, coder == "second"),
  tolerance = 0
)
category_agreement(
  filter(coders, coder == "main"),
  filter(coders, coder == "second"),
  tolerance = 1
)
