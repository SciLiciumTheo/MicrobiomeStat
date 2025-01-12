#' @title Generate Boxplot of Individual Taxa Abundance Over Time
#'
#' @description This function creates a boxplot showing the abundance distribution of individual taxa at a specified taxonomic level over time from longitudinal data. It takes a MicrobiomeStat data object as input.
#'
#' @param data.obj A list object in a format specific to MicrobiomeStat, which can include components such as feature.tab (matrix), feature.ann (matrix), meta.dat (data.frame), tree, and feature.agg.list (list).
#' @param subject.var A character string specifying the subject variable in the metadata.
#' @param time.var A character string specifying the time variable in the metadata.
#' @param t0.level Character or numeric, baseline time point for longitudinal analysis, e.g. "week_0" or 0. Required.
#' @param ts.levels Character vector, names of follow-up time points, e.g. c("week_4", "week_8"). Required.
#' @param group.var Optional grouping variable in metadata.
#' @param strata.var Optional stratification variable in metadata.
#' @param feature.level Taxonomic level(s) for boxplots.
#' @param features.plot A character vector specifying which feature IDs (e.g. OTU IDs) to plot.
#' Default is NULL, in which case features will be selected based on `top.k.plot` and `top.k.func`.
#' @param feature.dat.type The type of the feature data, which determines how the data is handled in downstream analyses.
#' Should be one of:
#' - "count": Raw count data, will be normalized by the function.
#' - "proportion": Data that has already been normalized to proportions/percentages.
#' - "other": Custom abundance data that has unknown scaling. No normalization applied.
#' The choice affects preprocessing steps as well as plot axis labels.
#' Default is "count", which assumes raw OTU table input.
#' @param top.k.plot A numeric value specifying the number of top taxa to be plotted if features.plot is NULL. If NULL (default), all taxa will be plotted.
#' @param top.k.func A function to compute the top k taxa if features.plot is NULL. If NULL (default), the mean function will be used.
#' @param transform A string indicating the transformation to apply to the data before plotting. Options are:
#' - "identity": No transformation (default)
#' - "sqrt": Square root transformation
#' - "log": Logarithmic transformation. Zeros are replaced with half of the minimum non-zero value for each taxon before log transformation.
#' @param prev.filter Numeric value specifying the minimum prevalence threshold for filtering
#' taxa before analysis. Taxa with prevalence below this value will be removed.
#' Prevalence is calculated as the proportion of samples where the taxon is present.
#' Default 0 removes no taxa by prevalence filtering.
#' @param abund.filter Numeric value specifying the minimum abundance threshold for filtering
#' taxa before analysis. Taxa with mean abundance below this value will be removed.
#' Abundance refers to counts or proportions depending on \code{feature.dat.type}.
#' Default 0 removes no taxa by abundance filtering.
#' @param base.size Base font size for the generated plots.
#' @param theme.choice Plot theme choice. Can be one of:
#'   - "prism": ggprism::theme_prism()
#'   - "classic": theme_classic()
#'   - "gray": theme_gray()
#'   - "bw": theme_bw()
#' Default is "bw".
#' @param custom.theme A custom ggplot theme provided as a ggplot2 theme object. This allows users to override the default theme and provide their own theme for plotting. To use a custom theme, first create a theme object with ggplot2::theme(), then pass it to this argument. For example:
#'
#' ```r
#' my_theme <- ggplot2::theme(
#'   axis.title = ggplot2::element_text(size=16, color="red"),
#'   legend.position = "none"
#' )
#' ```
#'
#' Then pass `my_theme` to `custom.theme`. Default is NULL, which will use the default theme based on `theme.choice`.
#' @param palette Color palette used for the plots.
#' @param pdf Logical, if TRUE save plot as a multi-page PDF file. Default is TRUE.
#' @param file.ann Optional string for file annotation to add to PDF name.
#' @param pdf.wid Width of the PDF plots.
#' @param pdf.hei Height of the PDF plots.
#' @param ... Additional arguments passed to ggplot2 functions.
#'
#' @return A ggplot object showing the abundance distribution of taxa over time.
#'
#' @examples
#' \dontrun{
#' # Generate the boxplot pair
#' data(ecam.obj)
#' generate_taxa_indiv_boxplot_long(
#'   data.obj = ecam.obj,
#'   subject.var = "studyid",
#'   time.var = "month",
#'   t0.level = NULL,
#'   ts.levels = NULL,
#'   group.var = NULL,
#'   strata.var = NULL,
#'   feature.level = c("Phylum"),
#'   feature.dat.type = "proportion",
#'   transform = "log",
#'   prev.filter = 0.01,
#'   abund.filter = 0.01,
#'   base.size = 20,
#'   theme.choice = "bw",
#'   custom.theme = NULL,
#'   palette = c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
#'   "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf", "#aec7e8",
#'   "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5", "#c49c94", "#f7b6d2",
#'   "#c7c7c7", "#dbdb8d", "#9edae5", "#f0f0f0", "#3182bd"),
#'   pdf = TRUE,
#'   file.ann = NULL,
#'   pdf.wid = 11,
#'   pdf.hei = 8.5
#' )
#'
#' data(peerj32.obj)
#'
#' generate_taxa_indiv_boxplot_long(
#'   data.obj = peerj32.obj,
#'   subject.var = "subject",
#'   time.var = "time",
#'   t0.level = "1",
#'   ts.levels = "2",
#'   group.var = "group",
#'   strata.var = NULL,
#'   feature.level = c("Family"),
#'   features.plot = NULL,
#'   feature.dat.type = "other",
#'   top.k.plot = NULL,
#'   top.k.func = NULL,
#'   transform = "log",
#'   prev.filter = 0.01,
#'   abund.filter = 0.01,
#'   base.size = 20,
#'   theme.choice = "bw",
#'   custom.theme = NULL,
#'   palette = NULL,
#'   pdf = TRUE,
#'   file.ann = NULL,
#'   pdf.wid = 11,
#'   pdf.hei = 8.5
#' )
#' }
#' @export
generate_taxa_indiv_boxplot_long <-
  function(data.obj,
           subject.var,
           time.var,
           t0.level = NULL,
           ts.levels = NULL,
           group.var = NULL,
           strata.var = NULL,
           feature.level = NULL,
           features.plot = NULL,
           feature.dat.type = c("count", "proportion", "other"),
           top.k.plot = NULL,
           top.k.func = NULL,
           transform = c("identity", "sqrt", "log"),
           prev.filter = 0.01,
           abund.filter = 0.01,
           base.size = 16,
           theme.choice = "prism",
           custom.theme = NULL,
           palette = NULL,
           pdf = TRUE,
           file.ann = NULL,
           pdf.wid = 11,
           pdf.hei = 8.5,
           ...) {

    feature.dat.type <- match.arg(feature.dat.type)

    mStat_validate_data(data.obj)

    if (!is.character(subject.var))
      stop("`subject.var` should be a character string.")
    if (!is.character(time.var))
      stop("`time.var` should be a character string.")
    if (!is.null(group.var) &&
        !is.character(group.var))
      stop("`group.var` should be a character string or NULL.")
    if (!is.null(strata.var) &&
        !is.character(strata.var))
      stop("`strata.var` should be a character string or NULL.")

    # 提取数据
    data.obj <- mStat_process_time_variable(data.obj, time.var, t0.level, ts.levels)

    meta_tab <- load_data_obj_metadata(data.obj) %>% as.data.frame() %>% select(all_of(c(subject.var,group.var,time.var,strata.var)))

    if (feature.dat.type == "count") {
      message(
        "Your data is in raw format ('Raw'). Normalization is crucial for further analyses. Now, 'mStat_normalize_data' function is automatically applying 'Rarefy-TSS' transformation."
      )
      otu_tab <-
        load_data_obj_count(mStat_normalize_data(data.obj, method = "Rarefy-TSS")$data.obj.norm)
    } else{
      otu_tab <- load_data_obj_count(data.obj)
    }

    tax_tab <- load_data_obj_taxonomy(data.obj) %>%
      as.data.frame() %>%
      {if("original" %in% feature.level) dplyr::mutate(., original = rownames(.)) else .} %>%
      select(all_of(feature.level))

    line_aes_function <- if (!is.null(group.var)) {
      aes(
        x = !!sym(time.var),
        y = value,
        group = !!sym(subject.var),
        color = !!sym(group.var)
      )
    } else {
      aes(
        x = !!sym(time.var),
        y = value,
        group = !!sym(subject.var)
      )
    }

    aes_function <- if (!is.null(group.var)) {
      aes(
        x = !!sym(time.var),
        y = value,
        fill = !!sym(group.var)
      )
    } else {
      aes(
        x = !!sym(time.var),
        y = value,
        fill = !!sym(time.var)
      )
    }

    # 设置颜色，根据 time.var 的唯一值数量生成颜色列表
    if (is.null(palette)){
      col <-
        c(
          "#E31A1C",
          "#1F78B4",
          "#FB9A99",
          "#33A02C",
          "#FDBF6F",
          "#B2DF8A",
          "#A6CEE3",
          "#BA7A70",
          "#9D4E3F",
          "#829BAB"
        )
    } else{
      col <- palette
    }

    theme_function <- switch(theme.choice,
                             prism = ggprism::theme_prism(),
                             classic = theme_classic(),
                             gray = theme_gray(),
                             bw = theme_bw(),
                             ggprism::theme_prism()) # 根据用户选择设置主题

    # 使用用户自定义主题（如果提供），否则使用默认主题
    theme_to_use <- if (!is.null(custom.theme)) custom.theme else theme_function

    if (feature.dat.type == "other" || !is.null(features.plot) ||
        (!is.null(top.k.func) && !is.null(top.k.plot))) {
      prev.filter <- 0
      abund.filter <- 0
    }

    plot_list_all <- lapply(feature.level, function(feature.level) {
      otu_tax <-
        cbind(otu_tab,
          tax_tab %>% select(all_of(feature.level)))

      otu_tax_filtered <- otu_tax %>%
        tidyr::gather(key = "sample", value = "value", -one_of(feature.level)) %>%
        dplyr::group_by_at(vars(!!sym(feature.level))) %>%
        dplyr::summarise(total_count = mean(value),
                  prevalence = sum(value > 0) / dplyr::n()) %>%
        filter(prevalence >= prev.filter, total_count >= abund.filter) %>%
        select(-total_count, -prevalence) %>%
        dplyr::left_join(otu_tax, by = feature.level)

      otu_tax_agg <- otu_tax_filtered %>%
        tidyr::gather(key = "sample", value = "value", -one_of(feature.level)) %>%
        dplyr::group_by_at(vars(sample, !!sym(feature.level))) %>%
        dplyr::summarise(value = sum(value)) %>%
        tidyr::spread(key = "sample", value = "value")

      compute_function <- function(top.k.func) {
        if (is.function(top.k.func)) {
          results <-
            top.k.func(otu_tax_agg %>% column_to_rownames(feature.level) %>% as.matrix())
        } else {
          switch(top.k.func,
                 "mean" = {
                   results <-
                     rowMeans(otu_tax_agg %>% column_to_rownames(feature.level) %>% as.matrix(),
                              na.rm = TRUE)
                 },
                 "sd" = {
                   results <-
                     matrixStats::rowSds(otu_tax_agg %>% column_to_rownames(feature.level) %>% as.matrix(),
                            na.rm = TRUE)
                   names(results) <- rownames(otu_tax_agg %>% column_to_rownames(feature.level) %>% as.matrix())
                 },
                 stop("Invalid function specified"))
        }

        return(results)
      }

      if (is.null(features.plot) &&
          !is.null(top.k.plot) && !is.null(top.k.func)) {
        features.plot <- names(sort(compute_function(top.k.func), decreasing = TRUE)[1:top.k.plot])
      }

      otu_tax_agg_numeric <- otu_tax_agg %>%
        tidyr::gather(key = "sample", value = "value", -one_of(feature.level)) %>%
        dplyr::mutate(value = as.numeric(value))

      otu_tax_agg_merged <-
        dplyr::left_join(otu_tax_agg_numeric, meta_tab %>% rownames_to_column("sample"), by = "sample") %>%
        select(one_of(c("sample",
               feature.level,
               subject.var,
               time.var,
               group.var,
               strata.var,
               "value")))

      # Apply transformation
      if (feature.dat.type %in% c("count","proportion")){
        # Apply transformation
        if (transform %in% c("identity", "sqrt", "log")) {
          if (transform == "identity") {
            # No transformation needed
          } else if (transform == "sqrt") {
            otu_tax_agg_merged$value <- sqrt(otu_tax_agg_merged$value)
          } else if (transform == "log") {
            # Find the half of the minimum non-zero proportion for each taxon
            min_half_nonzero <- otu_tax_agg_merged %>%
              dplyr::group_by(!!sym(feature.level)) %>%
              filter(sum(value) != 0) %>%
              dplyr::summarise(min_half_value = min(value[value > 0]) / 2) %>%
              dplyr::ungroup()
            # Replace zeros with the log of the half minimum non-zero proportion
            otu_tax_agg_merged <- otu_tax_agg_merged %>%
              dplyr::group_by(!!sym(feature.level)) %>%
              filter(sum(value) != 0) %>%
              dplyr::ungroup() %>%
              dplyr::left_join(min_half_nonzero, by = feature.level) %>%
              dplyr::mutate(value = ifelse(value == 0, log10(min_half_value), log10(value))) %>%
              select(-min_half_value)
          }
        }
      }

      taxa.levels <-
        otu_tax_agg_merged %>% select(feature.level) %>% dplyr::distinct() %>% dplyr::pull()

      n_subjects <- length(unique(otu_tax_agg_merged[[subject.var]]))
      n_times <- length(unique(otu_tax_agg_merged[[time.var]]))

      if (!is.null(features.plot)){
        taxa.levels <- taxa.levels[taxa.levels %in% features.plot]
      }

      plot_list <- lapply(taxa.levels, function(tax) {

        sub_otu_tax_agg_merged <- otu_tax_agg_merged %>% filter(!!sym(feature.level) == tax)

        # 在数据处理部分创建一个新的数据框
        average_sub_otu_tax_agg_merged <- NULL
        if (n_times > 10 || n_subjects > 25) {
          if (!is.null(group.var) && !is.null(strata.var)) {
            average_sub_otu_tax_agg_merged <- sub_otu_tax_agg_merged %>%
              dplyr::group_by(!!sym(strata.var), !!sym(group.var), !!sym(time.var)) %>%
              dplyr::summarise(dplyr::across(value, \(x) mean(x, na.rm = TRUE)), .groups = "drop") %>%
              dplyr::ungroup() %>%
              dplyr::mutate(!!sym(subject.var) := "ALL")
          } else if (!is.null(group.var)) {
            average_sub_otu_tax_agg_merged <- sub_otu_tax_agg_merged %>%
              dplyr::group_by(!!sym(group.var), !!sym(time.var)) %>%
              dplyr::summarise(dplyr::across(value, \(x) mean(x, na.rm = TRUE)), .groups = "drop") %>%
              dplyr::ungroup() %>%
              dplyr::mutate(!!sym(subject.var) := "ALL")
          } else {
            average_sub_otu_tax_agg_merged <- sub_otu_tax_agg_merged %>%
              dplyr::group_by(!!sym(time.var)) %>%
              dplyr::summarise(dplyr::across(value, \(x) mean(x, na.rm = TRUE)), .groups = "drop") %>%
              dplyr::ungroup() %>%
              dplyr::mutate(!!sym(subject.var) := "ALL")
          }
        }

        boxplot <-
          ggplot(sub_otu_tax_agg_merged,
                 aes_function) +
          geom_violin(trim = FALSE, alpha = 0.8) +
          stat_boxplot(
            geom = "errorbar",
            position = position_dodge(width = 0.2),
            width = 0.1
          ) +
          geom_boxplot(
            position = position_dodge(width = 0.8),
            width = 0.1,
            fill = "white"
          ) +
          geom_line(
            line_aes_function,
            alpha = 1,
            linewidth = 0.6,
            color = "black",
            linetype = "dashed", # 更改线条类型为虚线
            data = if (!is.null(average_sub_otu_tax_agg_merged)) average_sub_otu_tax_agg_merged else sub_otu_tax_agg_merged
          ) +
          scale_fill_manual(values = col) +
          {
            if (feature.dat.type == "other"){
              labs(
                x = time.var,
                y = "Abundance",
                title = tax
              )
            } else {
              labs(
                x = time.var,
                y = paste("Relative Abundance(", transform, ")"),
                title = tax
              )
            }
          } +
          theme_to_use +
          theme(
            panel.spacing.x = unit(0, "cm"),
            panel.spacing.y = unit(0, "cm"),
            plot.title = element_text(hjust = 0.5, size = 20),
            strip.text.x = element_text(size = 12, color = "black"),
            axis.text = element_text(color = "black"),
            axis.text.x = element_text(color = "black", size = base.size),
            axis.text.y = element_text(color = "black", size = (base.size-2)),
            axis.title.x = element_text(size = base.size),
            axis.title.y = element_text(size = base.size),
            axis.ticks.x = element_blank(),
            plot.margin = unit(c(0.3, 0.3, 0.3, 0.3), units = "cm"),
            legend.text = ggplot2::element_text(size = 16),
            legend.title = ggplot2::element_text(size = 16)
          )

          if (!is.null(group.var)) {
            if (is.null(strata.var)) {
              boxplot <-
                boxplot + ggh4x::facet_nested(as.formula(paste("~", group.var)), scales = "fixed")
            } else {
              boxplot <-
                boxplot + ggh4x::facet_nested(as.formula(paste("~", strata.var, "+", group.var)), scales = "free", space = "free") + theme(panel.spacing = unit(0,"lines"))
            }
          }

        # Add geom_jitter() if the number of unique time points or subjects is greater than 10
        if (n_subjects > 20 || n_times > 10) {
          boxplot <- boxplot + geom_jitter(width = 0.1, alpha = 0.1, size = 1)
        }

        if (feature.dat.type != "other"){
          # 添加对Y轴刻度的修改
          if (transform == "sqrt") {
            boxplot <- boxplot + scale_y_continuous(
              labels = function(x) sapply(x, function(i) as.expression(substitute(a^b, list(a = i, b = 2))))
            )
          } else if (transform == "log") {
            boxplot <- boxplot + scale_y_continuous(
              labels = function(x) sapply(x, function(i) as.expression(substitute(10^a, list(a = i))))
            )
          }
        }

        return(boxplot)
      })


      # Save the plots as a PDF file
      if (pdf) {
        pdf_name <- paste0(
          "taxa_indiv_boxplot_long",
          "_",
          "subject_",
          subject.var,
          "_",
          "time_",
          time.var,
          "_",
          "feature_level_",
          feature.level,
          "_",
          "transform_",
          transform,
          "_",
          "prev_filter_",
          prev.filter,
          "_",
          "abund_filter_",
          abund.filter
        )
        if (!is.null(group.var)) {
          pdf_name <- paste0(pdf_name, "_", "group_", group.var)
        }
        if (!is.null(strata.var)) {
          pdf_name <- paste0(pdf_name, "_", "strata_", strata.var)
        }
        if (!is.null(file.ann)) {
          pdf_name <- paste0(pdf_name, "_", file.ann)
        }
        pdf_name <- paste0(pdf_name,"_", feature.level, ".pdf")
        # Create a multi-page PDF file
        pdf(pdf_name, width = pdf.wid, height = pdf.hei)
        # Use lapply to print each ggplot object in the list to a new PDF page
        lapply(plot_list, print)
        # Close the PDF device
        dev.off()
      }

      return(plot_list)
    })
    return(plot_list_all)
  }
