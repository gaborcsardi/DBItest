expect_arglist_is_empty <- function(object) {
  act <- quasi_label(rlang::enquo(object), arg = "object")
  act$formals <- formals(act$val)
  expect(
    is.null(act$formals),
    sprintf("%s has an empty argument list.", act$lab)
  )

  invisible(act$val)
}

expect_all_args_have_default_values <- function(object) {
  act <- quasi_label(rlang::enquo(object), arg = "object")
  act$args <- formals(act$val)
  act$args <- act$args[names(act$args) != "..."]
  act$char_args <- vapply(act$args, as.character, character(1L))
  expect(
    all(nzchar(act$char_args, keepNA = FALSE)),
    sprintf("%s has arguments without default values", act$lab)
  )

  invisible(act$val)
}

has_method <- function(method_name) {
  function(x) {
    my_class <- class(x)
    expect_true(
      length(findMethod(method_name, my_class)) > 0L,
      paste("object of class", my_class, "has no", method_name, "method")
    )
  }
}

expect_visible <- function(code) {
  ret <- withVisible(code)
  expect_true(ret$visible)
  ret$value
}

expect_invisible_true <- function(code) {
  ret <- withVisible(code)
  expect_true(ret$value)
  expect_false(ret$visible)

  invisible(ret$value)
}

expect_equal_df <- function(actual, expected) {
  factor_cols <- vapply(expected, is.factor, logical(1L))
  expected[factor_cols] <- lapply(expected[factor_cols], as.character)

  asis_cols <- vapply(expected, inherits, "AsIs", FUN.VALUE = logical(1L))
  expected[asis_cols] <- lapply(expected[asis_cols], unclass)

  list_cols <- vapply(expected, is.list, logical(1L))

  if (!any(list_cols)) {
    order_actual <- do.call(order, actual)
    order_expected <- do.call(order, expected)
  } else {
    expect_false(all(list_cols))
    expect_equal(anyDuplicated(actual[!list_cols]), 0)
    expect_equal(anyDuplicated(expected[!list_cols]), 0)
    order_actual <- do.call(order, actual[!list_cols])
    order_expected <- do.call(order, expected[!list_cols])
  }

  has_rownames_actual <- is.character(attr(actual, "row.names"))
  has_rownames_expected <- is.character(attr(expected, "row.names"))
  expect_equal(has_rownames_actual, has_rownames_expected)

  if (has_rownames_actual) {
    expect_equal(sort(row.names(actual)), sort(row.names(expected)))
  }

  actual <- unrowname(actual[order_actual, ])
  expected <- unrowname(expected[order_expected, ])

  expect_identical(actual, expected)
}
