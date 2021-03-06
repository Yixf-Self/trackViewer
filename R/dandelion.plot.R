#' dandelion.plots
#' @description Plot variants and somatic mutations
#' @param SNP.gr A object of \link[GenomicRanges:GRanges-class]{GRanges} or 
#' \link[GenomicRanges:GRangesList-class]{GRangesList}. All the width of GRanges must be 1.
#' @param features A object of \link[GenomicRanges:GRanges-class]{GRanges} or
#' \link[GenomicRanges:GRangesList-class]{GRangesList}.
#' @param ranges A object of \link[GenomicRanges:GRanges-class]{GRanges} or 
#' \link[GenomicRanges:GRangesList-class]{GRangesList}.
#' @param type Character. Could be fan, circle, pie or pin.
#' @param newpage plot in the new page or not.
#' @param ylab plot ylab or not. If it is a character vector, 
#' the vector will be used as ylab.
#' @param xaxis,yaxis plot xaxis/yaxis or not. If it is a numeric vector with length 
#' greater than 1, the vector will be used as the 
#' points at which tick-marks are to be drawn. And the names of the vector will be
#' used to as labels to be placed at the tick points if it has names. 
#' @param legend If it is a list with named color vectors, a legend will be added.
#' @param cex cex will control the size of circle.
#' @param maxgaps maxgaps between the stem of dandelions. 
#' It is calculated by the width of plot region devided by maxgaps. 
#' If a GRanges object is set, the dandelions stem will be clusted in each genomic range.
#' @param heightMethod A function used to determine the height of stem of dandelion. eg. Mean. Default is length.
#' @param ... not used.
#' @details In SNP.gr and features, metadata of the GRanges object will be used to 
#' control thecolor, fill, border, height, data source of pie if the type is pie.
#' @return NULL
#' @import GenomicRanges
#' @import grid
#' @importClassesFrom grImport Picture
#' @importFrom grImport readPicture grid.picture
#' @export
#' @examples
#' SNP <- c(10, 100, 105, 108, 400, 410, 420, 600, 700, 805, 840, 1400, 1402)
#' SNP.gr <- GRanges("chr1", IRanges(SNP, width=1, names=paste0("snp", SNP)), 
#'                   score=sample.int(100, length(SNP))/100)
#' features <- GRanges("chr1", IRanges(c(1, 501, 1001), 
#'                                     width=c(120, 500, 405),
#'                                     names=paste0("block", 1:3)),
#'                     color="black",
#'                     fill=c("#FF8833", "#51C6E6", "#DFA32D"),
#'                     height=c(0.1, 0.05, 0.08))
#' dandelion.plot(SNP.gr, features, type="fan")

dandelion.plot <- function(SNP.gr, features=NULL, ranges=NULL,
                      type=c("fan", "circle", "pie", "pin"),
                      newpage=TRUE, ylab=TRUE, 
                      xaxis=TRUE, yaxis=FALSE, legend=NULL, 
                      cex=1, maxgaps=1/50, heightMethod=NULL, ...){
    stopifnot(inherits(SNP.gr, c("GRanges", "GRangesList")))
    stopifnot(inherits(features, c("GRanges", "GRangesList")))
    type <- match.arg(type)
    if(length(heightMethod)>0){
      stopifnot(is.function(heightMethod))
    }else{
      heightMethod <- length
    }
    if(is(maxgaps, "GRanges")){
      ol <- findOverlaps(maxgaps, drop.self=TRUE, drop.redundant=TRUE)
      if(length(ol)>0){
        stop("If maxgaps is an object of GRanges, maxgaps could not have overlaps.")
      }
    }
    if(type=="pin"){
        pinpath <- system.file("extdata", "map-pin-red.xml", package="trackViewer")
        pin <- readPicture(pinpath)
    }else{
        pin <- NULL
    }
    SNP.gr.name <- deparse(substitute(SNP.gr))
    if(is(SNP.gr, "GRanges")){
        SNP.gr <- GRangesList(SNP.gr)
        names(SNP.gr) <- SNP.gr.name
    }
    len <- length(SNP.gr)
    if(length(legend)>0){
        if(!is.list(legend)){
            tmp <- legend
            legend <- list()
            length(legend) <- len
            legend[[len]] <- tmp
            rm(tmp)
        }else{
            if(length(legend)==1){
                tmp <- legend[[1]]
                legend <- list()
                length(legend) <- len
                legend[[len]] <- tmp
                rm(tmp)
            }else{
                if("labels" %in% names(legend)){
                    tmp <- legend
                    legend <- list()
                    length(legend) <- len
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
    if(length(ranges)>0){
        stopifnot(is(ranges, "GRanges")&length(ranges)==length(SNP.gr))
    }else{
        if(is(features, "GRanges")){
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
    height <- 1/len
    if(newpage) grid.newpage()
    for(i in seq.int(len)){
        vp <- viewport(x=.5, y=height*(i-0.5), width=1, height=height)
        pushViewport(vp)
        lineW <- as.numeric(convertX(unit(1, "line"), "npc"))
        lineH <- as.numeric(convertY(unit(1, "line"), "npc"))
        ## ylab
        if(is.logical(ylab)){
            if(ylab && length(names(SNP.gr))>0){
                grid.text(names(SNP.gr)[i], x = lineW, 
                          y = .5, rot = 90)
            }
        }
        if(is.character(ylab)){
            if(length(ylab)==1) ylab <- rep(ylab, len)
            grid.text(ylab[i], x = lineW,
                      y = .5, rot = 90)
        }
        
        if(is(features, "GRangesList")){
            feature <- features[[i]]
        }else{
            feature <- features
        }
        ol <- findOverlaps(feature, ranges[i])
        feature <- feature[queryHits(ol)]
        start(feature)[start(feature)<start(ranges[i])] <- start(ranges[i])
        end(feature)[end(feature)>end(ranges[i])] <- end(ranges[i])
        baseline <- max(c(unlist(feature$height)/2, .0001)) + 0.2 * lineH
        gap <- .2 * lineH
        bottomblank <- 4
        if(length(names(feature))>0){
            feature.s <- feature[!duplicated(names(feature))]
            ncol <- getColNum(names(feature.s))
            bottomblank <- max(ceiling(length(names(feature.s)) / ncol), 4)
            pushViewport(viewport(x=.5, y=bottomblank*lineH/2, 
                                  width=1,
                                  height=bottomblank*lineH,
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
        pushViewport(viewport(x=lineW + .5, y= (bottomblank+2)*lineH/2 + .5, 
                              width= 1 - 7*lineW,
                              height= 1 - (bottomblank+2)*lineH,
                              xscale=c(start(ranges[i]), end(ranges[i]))))
        ## axis
        if(length(xaxis)==1 && as.logical(xaxis)) {
            grid.xaxis()
        }
        if(length(xaxis)>1 && is.numeric(xaxis)){
            xaxisLabel <- names(xaxis)
            if(length(xaxisLabel)!=length(xaxis)) xaxisLabel <- TRUE
            grid.xaxis(at=xaxis, label=xaxisLabel)
        }
        
        ##baseline
        grid.lines(x=c(0, 1), y=c(baseline, baseline)) #baseline
        
        for(m in 1:length(feature)){
            this.dat <- feature[m]
            color <- if(is.list(this.dat$color)) this.dat$color[[1]] else this.dat$color
            fill <- if(is.list(this.dat$fill)) this.dat$fill[[1]] else this.dat$fill
            this.cex <- if(length(this.dat$cex)>0) this.dat$cex[[1]][1] else 1
            width <- if(length(this.dat$height)>0) this.dat$height[[1]][1] else 2*baseline
            rot <- if(length(this.dat$rot)>0) this.dat$rot[[1]][1] else 45
            grid.rect(x=start(this.dat), y=baseline, width=width(this.dat), height=width,
                      just="left", gp=gpar(col=color, fill=fill), default.units = "native")
        }
        SNPs <- SNP.gr[[i]]
        if(length(SNPs)>0){
            strand(SNPs) <- "*"
            SNPs <- sort(SNPs)
            width <- 2 * baseline + 2*gap
            SNPs.groups <- SNPs
            mcols(SNPs.groups) <- NULL
            SNPs.groups$w <- 0
            SNPs.groups$idx <- seq_along(SNPs)
            if(length(SNPs)==length(SNPs$score)){
              SNPs.groups$score <- SNPs$score
            }else{
              SNPs.groups$score <- 0
            }
            if(is(maxgaps, "GRanges")){
              SNPs.ol <- countOverlaps(maxgaps, SNPs)
              maxgaps <- maxgaps[SNPs.ol>0]
              if(length(maxgaps)<1){
                stop("Can not cluster the SNPs by given maxgaps")
              }
              SNPs.ol <- findOverlaps(maxgaps, SNPs)
              SNPs.groups$gps <- length(maxgaps) + seq_along(SNPs)
              SNPs.groups$gps[subjectHits(SNPs.ol)] <- queryHits(SNPs.ol)
            }else{
              if(!is.numeric(maxgaps)){
                stop("maxgaps must be a number or GRanges.")
              }
              SNPs.gap <- gaps(SNPs)
              SNPs.gap <- SNPs.gap[as.character(seqnames(SNPs.gap)) %in% as.character(seqnames(ranges[i])) & as.character(strand(SNPs.gap))=="*" & start(SNPs.gap)>=start(ranges[i]) & end(SNPs.gap)<=end(ranges[i])]
              SNPs.gap$w <- width(SNPs.gap)
              range.width <- floor(width(ranges[i])*maxgaps)
              SNPs.gap$idx <- rep(0, length(SNPs.gap))
              SNPs.gap$score <- 0
              SNPs.groups <- sort(c(SNPs.gap, SNPs.groups))
              SNPs.groups$gps <- cumsum(SNPs.groups$w >=range.width)
              SNPs.groups <- SNPs.groups[SNPs.groups$idx>0]
              SNPs.groups <- SNPs.groups[order(SNPs.groups$idx)]
            }
            if(length(names(SNPs))>0){
              maxStrHeight <- 
                max(as.numeric(
                  convertY(stringWidth(names(SNPs)), "npc")
                ))+lineW/2
            }else{
              maxStrHeight <- 0
            }
            ratio.yx <- 1/as.numeric(convertX(unit(1, "snpc"), "npc"))
            ypos <- lineW*max(ratio.yx, 1.2) + maxStrHeight*cex + 2*lineH
            if(length(legend[[i]])>0){
              ypos <- ypos + 3*lineH
            }
            SNPs.groups <- Y1pos(SNPs.groups, c(start(ranges[i]), end(ranges[i])), lineW, width, cex, 
                                 ypos, 
                                 length(yaxis) > 1 || (length(yaxis)==1 && as.logical(yaxis)), heightMethod)
            
            # yaxis
            yyscale <- c(0, SNPs.groups$yyscaleMax[1])
            if(length(yaxis)==1 && as.logical(yaxis)) {
              pushViewport(viewport(y= width + (1-width-ypos-cex*lineW*ratio.yx)/2, 
                                    height= 1 - width-ypos-cex*lineW*ratio.yx,
                                    yscale = yyscale))
              grid.yaxis()
              popViewport()
            }
            if(length(yaxis)>1 && is.numeric(yaxis)){
              yaxisLabel <- names(yaxis)
              if(length(yaxisLabel)!=length(yaxis)) yaxisLabel <- TRUE
              pushViewport(viewport(y= width + (1-width-ypos-cex*lineW*ratio.yx)/2, 
                                    height= 1 - width - ypos-cex*lineW*ratio.yx,
                                    yscale = yyscale))
              grid.yaxis(at=yaxis, label=yaxisLabel)
              popViewport()
            }
            ## legend
            scoreMax <- max(SNPs.groups$Y2, na.rm = TRUE)
            if(length(legend[[i]])>0){
              ypos <- width + lineW*max(ratio.yx, 1.2) + 
                scoreMax + maxStrHeight*cex
              if(is.list(legend[[i]])){
                thisLabels <- legend[[i]][["labels"]]
                gp <- legend[[i]][names(legend[[i]])!="labels"]
                class(gp) <- "gpar"
              }else{
                thisLabels <- names(legend[[i]])
                gp <- gpar(fill=legend[[i]]) 
              }
              if(length(thisLabels)>0){
                ncol <- getColNum(thisLabels)
                topblank <- ceiling(length(thisLabels) / ncol)
                pushViewport(viewport(x=.5, y=ypos+topblank*lineH/2, 
                                      width=1,
                                      height=topblank*lineH,
                                      just="bottom"))
                grid.legend(label=thisLabels, ncol=ncol,
                            byrow=TRUE, vgap=unit(.2, "lines"),
                            pch=21,
                            gp=gp)
                popViewport()
              }
            }
            for(m in 1:length(SNPs)){
                this.dat <- SNPs[m]
                this.dat.grp <- SNPs.groups[m]
                color <- if(is.list(this.dat$color)) this.dat$color[[1]] else this.dat$color
                border <- if(is.list(this.dat$border)) this.dat$border[[1]] else this.dat$border
                fill <- if(is.list(this.dat$fill)) this.dat$fill[[1]] else this.dat$fill
                lwd <- if(is.list(this.dat$lwd)) this.dat$lwd[[1]] else this.dat$lwd
                id <- if(is.character(this.dat$label)) this.dat$label else NA
                id.col <- if(length(this.dat$label.col)>0) this.dat$label.col else "black"
                this.dat.mcols <- mcols(this.dat)
                this.dat.mcols <- this.dat.mcols[, !colnames(this.dat.mcols) %in% c("color", "fill", "lwd", "id", "id.col", "cex"), drop=FALSE]
                grid.dandelion(x0=(start(this.dat)-start(ranges[i]))/width(ranges[i]), 
                              y0=baseline,
                              x1=(start(this.dat)-start(ranges[i]))/width(ranges[i]),
                              y1=this.dat.grp$Y1,
                              x2=(this.dat.grp$X2-start(ranges[i]))/width(ranges[i]), 
                              y2=this.dat.grp$Y2, 
                              radius=cex*lineW/2,
                              col=color,
                              border=border,
                              percent=this.dat.mcols,
                              edges=100,
                              alpha=this.dat.grp$alpha,
                              type=type,
                              ratio.yx=ratio.yx,
                              pin=pin,
                              scoreMax=scoreMax,
                              id=id, id.col=id.col, 
                              name=names(this.dat), 
                              cex=cex, lwd=lwd)
            }
        }
        
        popViewport()
        popViewport()
    }
}