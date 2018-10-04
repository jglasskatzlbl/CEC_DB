#Modified RF Impute package specific to this project
#The goal is to add a deterministic layer
#We need to ensure the base property that E = V*D/(OPPE/100) remains true
#Also that 0<OPPE<100. It would be reasonable to fix OPPE in a tighter range
#Realistic energy levels could also be beneficial
#V,D, &E all must be >0

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
        lost <- filter(lost, is.finite(Electricity_kWh) & is.finite(Depth_ft))
        lost <- filter(lost, Electricity_kWh>0 & Depth_ft>0 & Volume_ac_ft>0)
        #define and impose the constraints. More constraints can be entered here
        #the frontier for KwhAF efficiency
        bad <- lost$Electricity_kWh/lost$Volume_ac_ft -1.472*Depth_ft < 0
        #another smart restriction would be to limit the ratio of Vol to energy to realistic bounds
        while(any(bad)){
          lost[bad,]$Electricity_kWh <- lost[bad,]$Electricity_kWh*1.005
          bad <- lost$Electricity_kWh/lost$Volume_ac_ft -1.472*Depth_ft < 0
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