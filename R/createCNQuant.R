#' createCNQuant
#'
#' createCNQuant is the class initialisation function. It takes segmented copy
#' number profiles as input and generates a `CNQuant` class object with
#' standardised input slots for downstream processing.
#'
#' @param data Unrounded absolute copy number data
#' @param experimentName A user-specified name of the experiment
#' @param build Genome build to use, either hg19 or hg38 or mm10 (default: hg19)
#' @details * data: Input data for this function should be unrounded (or
#'   rounded) copy number data which can be provided in various formats. In the
#'   first instance, copy number data can be a delimited file containing segment
#'   data for all samples with the following fields;
#'   "chromosome","start","end","segVal" & "sample". This should be specified as
#'   a file path. Secondly, data can be loaded as a data.frame object with the
#'   same fields specified previously and provided as the input data. Lastly, a
#'   `QDNAseqCopyNumbers` class object from the [QDNAseq
#'   package](https://github.com/ccagc/QDNAseq) can be used as an input file,
#'   from which a segment table is extracted.
#'   * experimentName: experimentName can be a character string to name the
#'   `CNQuant` class object for future reference. It currently has no usage in
#'   any functions.
#'   * build: character string to specify the genome build to use when extracting
#'    copy number features. Only human data using either hg19 or hg38 is
#'    currently supported, or mouse data using mm10.
#' @return A CNQuant class object
#' @seealso [CNQuant-class]
#' @seealso [quantifyCNSignatures()]
#' @examples
#'   data(TCGA_478_Samples_SNP6_GOLD)
#'   cnobj <- createCNQuant(TCGA_478_Samples_SNP6_GOLD,experimentName="myExp",build="hg19")
#' @export createCNQuant
#'
createCNQuant <- function(data=NULL,experimentName = "defaultExperiment",build = "hg19"){
    if(is.null(data)){
        stop("no data provided\n")
    }
    supported_builds <- c("hg19","hg38","mm10")
    if(!build %in% supported_builds){
        stop(paste0("unknown build - supported builds: ",
                    paste0(supported_builds,collapse = ", ")))
    }
    if(is.character(data)){
        if(!file.exists(data)){
            stop("File not found\n")
        }
        if(file.exists(data)){
            header <- colnames(data.table::fread(input = data,
                                                 header = T,
                                                 nrows = 1))
            if(!all(header %in% c("chromosome","start","end","segVal","sample"))){
                stop("Header does not match the required naming ['chromosome','start','end','segVal','sample']")
            }
            segTable <- data.table::fread(input = data,
                                          header = T)
            segTable <- segTable[,c("chromosome","start","end","segVal","sample")]
        }
    } else if("QDNAseqCopyNumbers" %in% class(data)){
        segTable <- getSegTable(x = data)
    } else if(is.data.frame(data)){
        header <- colnames(data)
        if(!all(header %in% c("chromosome","start","end","segVal","sample"))){
            stop("Header does not match the required naming ['chromosome','start','end','segVal','sample']")
        }
        segTable <- data
        segTable <- segTable[,c("chromosome","start","end","segVal","sample")]
    } else {
        stop("Unknown input format\n")
    }
    ## Binned inputs (fixed width not supported yet)
    # if(checkbinned(segTable)){
    #     #segTable <- getSegTable()
    #     #split(segTable,f = as.factor(segTable$sample))
    # } else {
    #     segTable <- split(segTable,f = as.factor(segTable$sample))
    # }
    if(checkSegValRounding(segTable$segVal)){
        warning("segVal appears to be rounded, copy number signatures
                        were defined on unrounded absolute copy numbers, use
                        caution when interpretting and comparing between rounded
                        and unrounded inputs.")
    }
    ## Temp split until fixed bin input implemented
    segTable <- checkInputTypes(segTable)
    segTable$chromosome <- checkChromosomeFormat(segTable$chromosome)
    segTable <- dropChromosomes(segTable)
    segTable <- droplevels(segTable)
    segTable <- split(segTable,f = as.factor(segTable$sample))
    samplefeatData <- generateSampleFeatData(x = segTable)
    methods::new("CNQuant",segments = segTable,samplefeatData = samplefeatData,
                 ExpData = methods::new("ExpQuant",
                                        build = build,
                                        init.date = as.character(Sys.time()),
                                        samples.full = length(segTable),
                                        samples.current = length(segTable),
                                        experimentName = experimentName))
}
