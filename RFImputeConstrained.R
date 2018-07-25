#Modified RF Impute package specific to this project
#The goal is to add a deterministic layer
#We need to ensure the base property that E = V*D/(OPPE/100) remains true
#Also that 0<OPPE<100. It would be reasonable to fix OPPE in a tighter range
#Realistic energy levels could also be beneficial

#Define the function
rfImputeRestricted <- function(x, ...)
  UseMethod("rfImputeRestricted")

rfImputeRestricted.formula <- function(x, data, ..., subset) {
  if (!inherits(x, "formula"))
    stop("method is only for formula objects")
  call <- match.call()
  m <- match.call(expand.dots = FALSE)
  names(m)[2] <- "formula"
  if (is.matrix(eval(m$data, parent.frame())))
    m$data <- as.data.frame(data)
  m$... <- NULL
  m$na.action <- as.name("na.pass")
  m[[1]] <- as.name("model.frame")
  m <- eval(m, parent.frame())
  Terms <- attr(m, "terms")
  attr(Terms, "intercept") <- 0
  y <- model.response(m)
  if (!is.null(y)) m <- m[,-1]
  for (i in seq(along=ncol(m))) {
    if(is.ordered(m[[i]])) m[[i]] <- as.numeric(m[[i]])
  }
  ret <- rfImputeRestricted.default(m, y, ...)
  names(ret)[1] <- deparse(as.list(x)[[2]])
  ret
}

rfImputeRestricted.default <- function(x, y, iter=5, ntree=300, restrictfun, resticted, restrictor, below =TRUE, ...) {
  if (any(is.na(y))) stop("Can't have NAs in", deparse(substitute(y)))
  if (!any(is.na(x))) stop("No NAs found in ", deparse(substitute(x)))
  #make sure the restricted is in the proper form
  if(!missing(restrictfun)){
    if(missing(restricted)) stop("You must specify the restricted parameters")
    if(! all(restricted %in% colnames(x))) stop("Restricted must be named columns in", deparse(substitute(x)))
  }
  
  xf <- data.frame(na.roughfix(x))
  hasNA <- which(apply(x, 2, function(x) any(is.na(x))))
  if (is.data.frame(x)) {
    isfac <- sapply(x, is.factor)
  } else {
    isfac <- rep(FALSE, ncol(x))
  }
  
  for (i in 1:iter) {
    prox <- randomForest(xf, y, ntree=ntree, ..., do.trace=ntree,
                         proximity=TRUE)$proximity
    for (j in hasNA) {
      miss <- which(is.na(x[, j]))
      if (isfac[j]) {
        lvl <- levels(x[[j]])
        catprox <- apply(prox[-miss, miss, drop=FALSE], 2,
                         function(v) lvl[which.max(tapply(v, x[[j]][-miss], mean))])
        xf[miss, j] <- catprox
      } else {
        sumprox <- colSums(prox[-miss, miss, drop=FALSE])
        xf[miss, j] <- (prox[miss, -miss, drop=FALSE] %*% xf[,j][-miss]) / (1e-8 + sumprox)
        #Add in our restrictions
        lost <- xf[miss,]
        lost <- filter(lost, is.finite(OPPE) & is.finite(Electricity_kWh) & is.finite(Depth_ft))
        big <- lost$Volume_ac_ft *lost$Depth_ft *100 /lost$OPPE > lost$Electricity_kWh*1.4
        small <- lost$Volume_ac_ft *lost$Depth_ft *100 /lost$OPPE < lost$Electricity_kWh*.6
        while(any(big | small)){
          if(any(big)){
            lost[big,]$Electricity_kWh <- lost[big,]$Electricity_kWh*1.05
            lost[big,]$OPPE <- lost[big,]$OPPE*1.05
          }
          if(any(small)){
            lost[small,]$Electricity_kWh <- lost[small,]$Electricity_kWh*.95
            lost[small,]$OPPE <- lost[small,]$OPPE*.95
          }
          big <- lost$Volume_ac_ft *lost$Depth_ft *100 /lost$OPPE > lost$Electricity_kWh*1.4
          small <- lost$Volume_ac_ft *lost$Depth_ft *100 /lost$OPPE < lost$Electricity_kWh*.6
        }
        xf[miss,] <- lost
      }
      NULL
    }
  }
  xf <- cbind(y, xf)
  names(xf)[1] <- deparse(substitute(y))
  xf
}