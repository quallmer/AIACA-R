# Steps 5 and 6. The reserved run.
#
# The specification is frozen (codebook/motive_codebook_v0.3.R) and the coders
# are declared (`models` and `max_tokens` in setup.R). Each part of the
# reserved material is then coded once: one request per document, each
# independent of the others. Everything returned is saved before any label is
# read. No label is read in this script.

source("R/setup.R")

# Code one part of the reserved material with the main model, repeat it with
# nothing changed, and code it with the second model.
code_reserved <- function(material, sentences) {
  main <- run_once(
    str_c("reserved_", material, "_claude-sonnet-5-5"),
    qlm_code(
      document_inputs(sentences),
      motive_codebook,
      model = models[["main"]],
      params = params(max_tokens = max_tokens),
      name = "main"
    )
  )
  list(
    main = main,
    again = run_once(
      str_c("reserved_", material, "_claude-sonnet-5-5_r2"),
      qlm_replicate(main, name = "repeat")
    ),
    second = run_once(
      str_c("reserved_", material, "_deepseek-flash"),
      qlm_replicate(main, model = models[["second"]], name = "second")
    )
  )
}

# Calibration Set A: 30 stories.
calibration_a <- code_reserved("CA", filter(read_stories(), set == "CA"))

# The first email test: the emails of nine of the 18 writers.
emails <- code_reserved(
  "UD2_first",
  filter(read_emails(), role == "reserved_first_test")
)

# Calibration Set B: one speech of 128 sentences. Coded only after its
# transcription has been checked.
calibration_b <- code_reserved("CB", read_speech())

# Requests that produced no coding.
map(c(calibration_a, emails, calibration_b), qlm_failures)
