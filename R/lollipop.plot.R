#' Lolliplots
#' @description Plot variants and somatic mutations
#' @param SNP.gr A object of \link[GenomicRanges:GRanges-class]{GRanges}, 
#' \link[GenomicRanges:GRangesList-class]{GRangesList}
#' or a list of \link[GenomicRanges:GRanges-class]{GRanges}.
#' All the width of GRanges must be 1.
#' @param features A object of \link[GenomicRanges:GRanges-class]{GRanges}, 
#' \link[GenomicRanges:GRangesList-class]{GRangesList}
#' or a list of \link[GenomicRanges:GRanges-class]{GRanges}. 
#' The metadata 'featureLayerID' are used for drawing features in different layers.
#'  See details in vignette.
#' @param ranges A object of \link[GenomicRanges:GRanges-class]{GRanges} or 
#' \link[GenomicRanges:GRangesList-class]{GRangesList}.
#' @param type character. Could be circle, pie, pin or pie.stack.
#' @param newpage Plot in the new page or not.
#' @param ylab Plot ylab or not. If it is a character vector, 
#' the vector will be used as ylab.
#' @param yaxis Plot yaxis or not.
#' @param xaxis Plot xaxis or not. If it is a numeric vector with length greater than 1, 
#' the vector will be used as the points at which tick-marks are to be drawn. 
#' And the names of the vector will be used to as labels to be placed at the tick 
#' points if it has names. 
#' @param legend If it is a list with named color vectors, a legend will be added.
#' @param cex cex will control the size of circle.
#' @param dashline.col color for the dashed line.
#' @param jitter jitter the position of nodes or labels.
#' @param rescale logical(1) or a dataframe with rescale from and to. Recalse the x-axis or not.
#' if dataframe is used, colnames must be from.start, from.end, to.start, to.end.
#' @param ... not used.
#' @return NULL
#' @details 
#' In SNP.gr and features, metadata of the GRanges object will be used to control the 
#' color, fill, border, height, cex, dashline.col, data source of pie if the type is pie. 
#' And also the controls for labels by name the metadata start as 
#' label.parameter.<properties> 
#' such as label.parameter.rot, label.parameter.gp. The parameter is used for 
#' \link[grid]{grid.text}. The metadata 'featureLayerID' for features are used 
#' for drawing features in different layers. The metadata 'SNPsideID' for SNP.gr
#' are used for determining the side of lollipops. And the 'SNPsideID' could only
#' be 'top' or 'bottom'.
#' @return NULL
#' @import GenomicRanges
#' @import IRanges
#' @import grid
#' @importFrom scales rescale
#' @importClassesFrom grImport Picture
#' @importFrom grImport readPicture grid.picture
#' @export
#' @examples
#' SNP <- c(10, 100, 105, 108, 400, 410, 420, 600, 700, 805, 840, 1400, 1402)
#' x <- sample.int(100, length(SNP))
#' SNP.gr <- GRanges("chr1", IRanges(SNP, width=1, names=paste0("snp", SNP)), 
#'                   value1=x, value2=100-x)
#' SNP.gr$color <- rep(list(c("red", 'blue')), length(SNP))
#' SNP.gr$border <- sample.int(7, length(SNP), replace=TRUE)
#' features <- GRanges("chr1", IRanges(c(1, 501, 1001), 
#'                                     width=c(120, 500, 405),
#'                                     names=paste0("block", 1:3)),
#'                     color="black",
#'                     fill=c("#FF8833", "#51C6E6", "#DFA32D"),
#'                     height=c(0.1, 0.05, 0.08),
#'                     label.parameter.rot=45)
#' lolliplot(SNP.gr, features, type="pie") 
#'

lolliplot <- function(SNP.gr, features=NULL, ranges=NULL,
                      type=c("circle", "pie", "pin", 
                             "pie.stack"),
                      newpage=TRUE, ylab=TRUE, yaxis=TRUE,
                      xaxis=TRUE, legend=NULL, cex=1, 
                      dashline.col="gray80", 
                      jitter=c("node", "label"), 
                      rescale=FALSE, ...){
    stopifnot(inherits(SNP.gr, c("GRanges", "GRangesList", "list")))
    stopifnot(inherits(features, c("GRanges", "GRangesList", "list")))
    jitter <- match.arg(jitter)
    rescale.old <- rescale
    xaxis.old <- xaxis
    if(type!="circle"&&jitter=="label"){
      jitter <- "node"
      warning("if jitter set to label, type must be cirle.")
      message("jitter is set to node.")
    }
    SNP.gr.name <- deparse(substitute(SNP.gr))
    if(is(SNP.gr, "GRanges")){
        SNP.gr <- GRangesList(SNP.gr)
        names(SNP.gr) <- SNP.gr.name
    }
    len <- length(SNP.gr)
    for(i in seq.int(len)){
        stopifnot(is(SNP.gr[[i]], "GRanges"))
    }
    
    TYPES <- c("circle", "pie", "pin", "pie.stack")
    if(any(!type %in% TYPES)){
        stop("Error in match argument: ",
             paste0("'type' should be one of '",  
                    paste(TYPES, collapse="', '"), "'."))
    }
    types <- rep(type, length=len)[1:len]
    rm(type)
    ############### handle legend ####################
    ## set the legend as a list, 
    ## if all the legend for different tracks is same
    ## set draw legend for last track later
    if(length(legend)>0){
        if(!is.list(legend)){
            tmp <- legend
            legend <- vector(mode = "list", length = len)
            legend[[len]] <- tmp
            rm(tmp)
        }else{
            if(length(legend)==1){
                tmp <- legend[[1]]
                legend <- vector(mode = "list", length = len)
                legend[[len]] <- tmp
                rm(tmp)
            }else{
                if("labels" %in% names(legend)){
                    tmp <- legend
                    legend <- vector(mode = "list", length = len)
                    legend[[len]] <- tmp
                    rm(tmp)
                }else{
                    if(length(legend)<len){
                        length(legend) <- len
                    }
                }
            }
        }
    }
    
    features.name <- deparse(substitute(features))
    
    ################ handle ranges #####################
    ## if !missing(ranges) set ranges as feature ranges
    if(length(ranges)>0){
        stopifnot(class(ranges)=="GRanges")
        ranges <- rep(ranges, length(SNP.gr))[1:length(SNP.gr)]
        stopifnot(length(ranges)==length(SNP.gr))
    }else{
        if(class(features)=="GRanges"){
            ranges <- range(features)[rep(1, len)]
        }else{
            if(length(features)!=len){
                stop("if both SNP.gr and features is GRangesList,",
                     " the lengthes of them should be identical.")
            }
            ranges <- unlist(GRangesList(lapply(features, range)))
        }
    }
    if(is(ranges, "GRanges")){
        ##cut all SNP.gr by the range
        for(i in len){
            range <- ranges[i]
            stopifnot(all(width(SNP.gr[[i]])==1))
            ol <- findOverlaps(SNP.gr[[i]], range)
            SNP.gr[[i]] <- SNP.gr[[i]][queryHits(ol)]
        }
    }
    
    ################## plot ############################
    ## total height == 1
    height <- 1/len
    height0 <- 0
    if(newpage) grid.newpage()
    for(i in 1:len){
        type <- match.arg(types[i], TYPES)
        if(type=="pin"){ ## read the pin shape file
            pinpath <- system.file("extdata", "map-pin-red.xml", package="trackViewer")
            pin <- readPicture(pinpath)
        }else{
            pin <- NULL
        }
        ## Here we don't know the real height of each tracks
        vp <- viewport(x=.5, y=height0 + height*0.5, width=1, height=height)
        pushViewport(vp)
        LINEW <- as.numeric(convertX(unit(1, "line"), "npc"))
        LINEH <- as.numeric(convertY(unit(1, "line"), "npc"))
        ## GAP the gaps between any elements
        GAP <- .2 * LINEH
        ratio.yx <- 1/as.numeric(convertX(unit(1, "snpc"), "npc"))
        
        
        SNPs <- SNP.gr[[i]]
        strand(SNPs) <- "*"
        SNPs <- sort(SNPs)
        
        ## prepare the feature
        if(inherits(features, c("GRangesList", "list"))){
            feature <- features[[i]]
            stopifnot(is(feature, "GRanges"))
        }else{
            feature <- features
        }
        
        ## rescale
        rescale <- rescale.old
        xaxis <- xaxis.old
        if(is.logical(rescale)[1]){
          if(rescale[1]){
            range.tile <- tile(ranges[i], n = 5)[[1]]
            if(all(width(range.tile)>2)){
              range.tile.cnt <- countOverlaps(range.tile, SNPs)
              feature.start <- feature.end <- feature
              end(feature.start) <- start(feature.start)
              start(feature.end) <- end(feature.end)
              range.tile.cnt2 <- countOverlaps(range.tile, unique(c(feature.start, feature.end)))
              range.tile.cnt <- range.tile.cnt + range.tile.cnt2
              range.width <- width(ranges[i])
              range.tile.width <- log2(range.tile.cnt + 1)
              range.tile.width <- range.tile.width/sum(range.tile.width)
              range.tile.width <- range.width * range.tile.width
              range.tile.width <- cumsum(range.tile.width)
              range.tile.width <- start(ranges[i]) + c(0, round(range.tile.width)-1)
              rescale <- data.frame(from.start=start(range.tile), from.end=end(range.tile),
                                    to.start=range.tile.width[-length(range.tile.width)],
                                    to.end=range.tile.width[-1])
              rescale$to.start[-1] <- rescale$to.start[-1] + 1
            }
          }
        }
        if(is.data.frame(rescale)){
          if(all(c("from.start", "from.end", "to.start", "to.end") %in% colnames(rescale))){
            rescale.gr <- function(x){
              if(is(x, "GRanges")){
                x.start <- start(x)
                x.end <- end(x)
                y <- c(x.start, x.end)
                x.cut <- cut(y, breaks=c(rescale$from.start[1], rescale$from.end+1),
                             labels=seq.int(nrow(rescale)), right=FALSE)
                y <- mapply(function(a, b){
                  if(!is.na(b)) {
                    rescale(a, to=c(rescale$to.start[b], rescale$to.end[b]),
                          from=c(rescale$from.start[b], rescale$from.end[b]))
                  }else{
                    a
                  }
                }, y, as.numeric(as.character(x.cut)))
                y <- round(y)
                start(x) <- 1
                end(x) <- y[seq_along(x)+length(x)]
                start(x) <- y[seq_along(x)]
                x
              }else{
                x.cut <- cut(x, breaks=c(rescale$from.start[1], rescale$from.end+1),
                             labels=seq.int(nrow(rescale)), right=FALSE)
                y <- mapply(function(a, b){
                  if(!is.na(b)) {
                    rescale(a, to=c(rescale$to.start[b], rescale$to.end[b]),
                            from=c(rescale$from.start[b], rescale$from.end[b]))
                  }else{
                    a
                  }
                }, x, as.numeric(as.character(x.cut)))
                y <- round(y)
                y
              }
            }
            feature <- rescale.gr(feature)
            SNPs <- rescale.gr(SNPs)
            if(is.logical(xaxis)[1]){
              xaxis <- c(rescale$to.start[1], rescale$to.end)
              names(xaxis) <- c(rescale$from.start[1], rescale$from.end)
            }else{
              xaxis.names <- names(xaxis)
              if(length(xaxis.names)!=length(xaxis)){
                xaxis.names <- as.character(xaxis)
              }
              xaxis <- rescale.gr(xaxis)
              names(xaxis) <- xaxis.names
            }
          }
        }
        
        ## convert height to npc number
        feature$height <- convertHeight2NPCnum(feature$height)
        ## multiple transcripts in one gene could be separated by featureLayerID
        if(length(feature$featureLayerID)!=length(feature)){
            feature$featureLayerID <- rep("1", length(feature))
        }
        feature <- feature[end(feature)>=start(ranges[i]) & 
                               start(feature)<=end(ranges[i])]
        feature$featureLayerID <- as.character(feature$featureLayerID)
        start(feature)[start(feature)<start(ranges[i])] <- start(ranges[i])
        end(feature)[end(feature)>end(ranges[i])] <- end(ranges[i])
        feature.splited <- split(feature, feature$featureLayerID)
        
        ## bottomblank, the transcripts legend height
        bottomblank <- 4
        if(length(names(feature))>0){ ## features legend
            feature.s <- feature[!duplicated(names(feature))]
            ncol <- getColNum(names(feature.s))
            bottomblank <- max(ceiling(length(names(feature.s)) / ncol), 4)
            pushViewport(viewport(x=.5, y=bottomblank*LINEH/2, 
                                  width=1,
                                  height=bottomblank*LINEH,
                                  xscale=c(start(ranges[i]), end(ranges[i]))))
            color <- if(length(unlist(feature.s$color))==length(feature.s)) 
                unlist(feature.s$color) else "black"
            fill <- if(length(unlist(feature.s$fill))==length(feature.s)) 
                unlist(feature.s$fill) else "black"
            pch <- if(length(unlist(feature.s$pch))==length(feature.s)) 
                unlist(feature.s$pch) else 22
            grid.legend(label=names(feature.s), ncol=ncol,
                        byrow=TRUE, vgap=unit(.2, "lines"),
                        pch=pch,
                        gp=gpar(col=color, fill=fill))
            popViewport()
        }else{
          if(length(xaxis)>1 || as.logical(xaxis[1])){
            bottomblank <- 2
          }else{
            bottomblank <- 0
          }
        }
        
        ## get the max score and scoreType
        scoreMax0 <- scoreMax <- 
            if(length(SNPs$score)>0) ceiling(max(c(SNPs$score, 1), na.rm=TRUE)) else 1
        if(type=="pie.stack") scoreMax <- length(unique(SNPs$stack.factor))
        if(!type %in% c("pie", "pie.stack")){
            if(length(yaxis)>1 && is.numeric(yaxis)){
                if(length(names(yaxis))!=length(yaxis)){
                    names(yaxis) <- yaxis
                }
                scoreMax0 <- max(yaxis, scoreMax0)
            }
            if(scoreMax>10) {
                SNPs$score <- 10*SNPs$score/scoreMax
                scoreMax <- 10*scoreMax0/scoreMax
            }else{
                scoreMax <- scoreMax0
            }
            scoreType <- 
                if(length(SNPs$score)>0) all(floor(SNPs$score)==SNPs$score) else FALSE
        }else{
            scoreType <- FALSE
        }
        
        ## if the type is caterpillar, there are lollipop in both sides
        ## plot the bottom lollipops first. And push a new viewport
        
        IsCaterpillar <- length(SNPs$SNPsideID) > 0
        if(IsCaterpillar){
            if(any(is.na(SNPs$SNPsideID)) || 
               !all(SNPs$SNPsideID %in% c('top', 'bottom'))){
                warning("Not all SNPsideID is top or bottom")
                IsCaterpillar <- FALSE
            }
        }
        
        if(IsCaterpillar){
            SNPs.top <- SNPs[SNPs$SNPsideID=='top']
            SNPs.bottom <- SNPs[SNPs$SNPsideID=='bottom']
        }else{
            SNPs.top <- SNPs
            SNPs.bottom <- GRanges()
        }
        if(length(SNPs.bottom)<1) IsCaterpillar <- FALSE
        ## viewport of plot region
        if(!IsCaterpillar){
            bottomblank <- bottomblank + 2 ## the height of xaxis
        }
        pushViewport(viewport(x=LINEW + .5, y=bottomblank*LINEH/2 + .5, 
                              width= 1 - 7*LINEW,
                              height= 1 - bottomblank*LINEH,
                              xscale=c(start(ranges[i]), end(ranges[i])),
                              clip="off"))
        
        plot.grid.xaxis <- function(col="black"){
            ## axis, should be in the bottom of transcripts
            if(length(xaxis)==1 && as.logical(xaxis)) {
                grid.xaxis(gp=gpar(col=col))
            }
            if(length(xaxis)>1 && is.numeric(xaxis)){
                xaxisLabel <- names(xaxis)
                if(length(xaxisLabel)!=length(xaxis)) xaxisLabel <- TRUE
                grid.xaxis(at=xaxis, label=xaxisLabel, gp=gpar(col=col))
            }
        }
        ## plot xaxis
        bottomHeight <- 0
        if(IsCaterpillar){
            ## total height == maxscore + extension + gap + labels
            bottomHeight <- getHeight(SNPs=SNPs.bottom, 
                                      ratio.yx=ratio.yx, 
                                      LINEW=LINEW, 
                                      GAP=GAP, 
                                      cex=cex, 
                                      type=type,
                                      scoreMax=scoreMax,
                                      level="data&labels")
            vp <- viewport(y=bottomHeight, just="bottom",
                           xscale=c(start(ranges[i]), end(ranges[i])))
            pushViewport(vp)
            plot.grid.xaxis("gray")
            popViewport()
        }else{
            plot.grid.xaxis()
        }
        
        ## the baseline, the center of the first transcript
        baseline <- 
            max(c(feature.splited[[1]]$height/2, 
                  .0001)) + 0.2 * LINEH
        baselineN <- 
            max(c(feature.splited[[length(feature.splited)]]$height/2, 
                .0001)) + 0.2 * LINEH
        
        ##plot features
        feature.height <- plotFeatures(feature.splited, LINEH, bottomHeight)
        
        if(length(SNPs.bottom)>0){
            plotLollipops(SNPs.bottom, feature.height, bottomHeight, baselineN, 
                          type, ranges[i], yaxis, scoreMax, scoreMax0, scoreType, 
                          LINEW, cex, ratio.yx, GAP, pin, dashline.col,
                          side="bottom", jitter=jitter)
        }
        feature.height <- feature.height + 2*GAP
        if(length(SNPs.top)>0){
            plotLollipops(SNPs.top, feature.height, bottomHeight, baseline, 
                          type, ranges[i], yaxis, scoreMax, scoreMax0, scoreType, 
                          LINEW, cex, ratio.yx, GAP, pin, dashline.col,
                          side="top", jitter=jitter)
        }
        
        ## legend
        this.height <- getHeight(SNPs.top, 
                                 ratio.yx, LINEW, GAP, cex, type,
                                 scoreMax=scoreMax,
                                 level="data&labels")
        this.height <- this.height + bottomHeight + feature.height
        this.height <- plotLegend(legend[[i]], this.height, LINEH)
        
        popViewport()
        
        this.height <- bottomblank*LINEH + 
            this.height * (1 - bottomblank*LINEH)
        
        ## ylab
        vp <- viewport(x=.5, y=this.height*0.5, 
                       width=1, height=this.height)
        pushViewport(vp)
        if(is.logical(ylab)){
            if(ylab && length(names(SNP.gr))>0){
                grid.text(names(SNP.gr)[i], x = LINEW, 
                          y = .5, rot = 90)
            }
        }
        if(is.character(ylab)){
            if(length(ylab)==1) ylab <- rep(ylab, len)
            grid.text(ylab[i], x = LINEW,
                      y = .5, rot = 90)
        }
        popViewport()
        
        popViewport()
        height0 <-  height0 + this.height*height
    }
}

