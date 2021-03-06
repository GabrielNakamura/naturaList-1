#' Classify occurrence records in levels of confidence in species determination
#'
#' @description Classify occurrence records in levels of confidence in species determination
#'
#' @param occ dataframe with occurrence records information.
#' @param spec dataframe with specialists' names
#' @param na.rm.coords logical. If TRUE, remove occurrences with NA in latitude or longitude
#' @param crit.levels character. Vector with levels of confidence in decreasing order.
#'        The criteria allowed are \code{det_by_spec}, \code{taxonomist},
#'        \code{image}, \code{sci_colection}, \code{field_obs}, \code{no_criteria_met}. See datails.
#'
#'
#' @param institution.source column of \code{occ} with the name of the institution that provided the data
#' @param collection.code column of \code{occ} with the codes for institution names
#' @param catalog.number column of \code{occ} with catalog number
#' @param year.event column with of \code{occ} the year of the collection event
#' @param date.identified column of \code{occ} with the date of species determination
#' @param scientific.name column of \code{occ} with the species names
#' @param determined.by column of \code{occ} with the name of who determined the species
#' @param longitude column with of \code{occ} longitude in decimal degrees
#' @param latitude column with of \code{occ} latitude in decimal degrees
#' @param basis.of.rec column of \code{occ} with the recording types, as in GBIF. See details.
#' @param media.type column of \code{occ} with the media type of recording. See details.
#' @param occ.id column of \code{occ} with link or code for the occurence record.
#'
#' @details basis.of.rec is a character vector with one of the following types:.... as in GBIF data 'basisOfRecord'
#' @details media.type uses the same pattern as GBIF data column mediaType.....
#'
#' @author Arthur V. Rodrigues
#'
#' @export

classify_occ <- function(occ,
                         spec = NULL,
                         na.rm.coords = TRUE,
                         crit.levels = c("det_by_spec",
                                         "taxonomist",
                                         "image",
                                         "sci_colection",
                                         "field_obs",
                                         "no_criteria_met"),
                         institution.source = "institutionCode",
                         collection.code = "collectionCode",
                         catalog.number = "catalogNumber",
                         year.event = "year",
                         date.identified = "dateIdentified",
                         scientific.name = "species",
                         determined.by = "identifiedBy",
                         longitude = "decimalLongitude",
                         latitude = "decimalLatitude",
                         basis.of.rec = "basisOfRecord",
                         media.type = "mediaType",
                         occ.id = "occurrenceID"){
  natList_column <- "naturaList_levels" %in% colnames(occ)
  if(natList_column){
    col.number <- grep("naturaList_levels",colnames(occ))
    occ <- occ[, -col.number]

    warning("'occ' already had classification. The classification was remake")
  }

  r.occ <- reduce.df(occ, na.rm.coords = na.rm.coords)

  if(!is.null(spec)){
    spec.list <- as.data.frame(sapply(spec, as.character), stringsAsFactors = F)
  }

  ## Classification
  lowest_level <- paste0(length(crit.levels), "_", "no_criteria_met")
  naturaList_levels <- rep(lowest_level, nrow(r.occ))

  for(i in length(crit.levels):1){

    if(crit.levels[i] == "field_obs"){
      field_obs_level <- paste0(i, "_", "field_obs")
      FObs <- which(r.occ$basis.of.rec %in% "HUMAN_OBSERVATION")
      naturaList_levels[FObs] <- field_obs_level
    }
    if(crit.levels[i] == "sci_colection"){
      sci_col_level <- paste0(i, "_", "sci_colection")
      SCol <- which(r.occ$basis.of.rec %in% "PRESERVED_SPECIMEN")
      naturaList_levels[SCol] <- sci_col_level
    }
    if(crit.levels[i] == "image"){
      image_level <- paste0(i, "_", "image")
      Img <- which(r.occ$media.type %in% "STILLIMAGE")
      naturaList_levels[Img] <- image_level
    }
    if(crit.levels[i] == "taxonomist"){
      tax_level <- paste0(i, "_", "taxonomist")
      Tax <- has.det.ID(r.occ)
      naturaList_levels[Tax] <- tax_level
    }
    if(crit.levels[i] == "det_by_spec"){

      DSpec <- which(r.occ$vec.crit %in% "f")


      if(!is.null(spec)){
        DSpec <- unlist(lapply(1:nrow(spec.list),
                               function(x) func.det.by.esp(r.occ, x, spec.list)))

        naturaList_levels[DSpec] <- apply(r.occ[DSpec,], 1,
                                          function(x) specialist.conference(x, spec.list))
      }
    }
  }
  # end of classification

  #df$vetor.criterio <- vetor.criterio



  rowID <- r.occ$rowID

  classified.occ <- cbind(occ[rowID, ], naturaList_levels)
  classified.occ <- check.spec(classified.occ, crit.levels, determined.by)
  classified.occ$naturaList_levels <- as.character(classified.occ$naturaList_levels)
  return(classified.occ)
}


