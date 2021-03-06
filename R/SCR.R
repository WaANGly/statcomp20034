#' @title A function computing the Mallows Model Average (MMA) least-squares estimates for pure nested candimate models.
#' @description A function computing the Mallows Model Average (MMA) least-squares estimates for pure nested candimate models.
#' @param y n×1 dependent varables
#' @param x n×p regressor matrix
#' @import quadprog
#' @importFrom stats runif rnorm
#' @return A list inluding parameter estimate, weight vector,fitted values,fitted residuals and Value of Mallows criterion.
#' @examples 
#' \dontrun{
#' y<-matrix(runif(10),nrow=10,ncol=1)
#' x<-matrix(rnorm(70),nrow=10,ncol=7)
#' MMAn(y,x)
#' }
#' @export
MMAn<-function(y,x){
  y <- as.matrix(y)
  x <- as.matrix(x)  
  n <- nrow(x)
  p <- ncol(x)
  # the selection matrix
  s <- matrix(1,nrow=p,ncol=p)
  s[upper.tri(s)] <- 0
  zero <- matrix(0,nrow=1,ncol=p)
  s <- rbind(zero,s) 
  m <- nrow(s)#the number of candidate models
  bbeta <- matrix(0,nrow=p,ncol=m)
  
  for (j in 1:m){
    ss <- matrix(1,nrow=n,ncol=1) %*% s[j,]
    index1 <- which(ss[,]==1)
    xs <- as.matrix(x[index1])
    xs <- matrix(xs,nrow=n,ncol=nrow(xs)/n)
    if (sum(ss)==0){
      xs <- x
      betas <- matrix(0,nrow=p,ncol=1)
      index2 <- matrix(c(1:p),nrow=p,ncol=1)  
    }  
    if (sum(ss)>0){
      betas <- solve(t(xs)%*%xs)%*%t(xs)%*%y 
      index2 <- as.matrix(which(s[j,]==1))  
    }
    beta0 <- matrix(0,nrow=p,ncol=1)
    beta0[index2] <- betas     
    bbeta[,j] <- beta0
  }
  ee <- y %*% matrix(1,nrow=1,ncol=m) - x %*% bbeta
  ehat <- y - x %*% bbeta[,m]
  sighat <- (t(ehat) %*% ehat)/(n-p)
  
  a1 <- t(ee) %*% ee
  if (qr(a1)$rank<ncol(ee)) a1 <- a1 + diag(m)*1e-10
  a2 <- matrix(c(-sighat*rowSums(s)),nrow=m,ncol=1)
  a3 <- t(rbind(matrix(1,nrow=1,ncol=m),diag(m),-diag(m)))
  a4 <- rbind(1,matrix(0,nrow=m,ncol=1),matrix(-1,nrow=m,ncol=1))
  
  w0 <- matrix(1,nrow=m,ncol=1)/m 
  w <- solve.QP(a1,a2,a3,a4,1)$solution
  w <- as.matrix(w)
  w <- (w*(w>0))/sum(w0)
  betahat <- bbeta %*% w
  yhat <- x %*% betahat # fitting values
  ehat <- y-yhat # fitting residuals
  cn=(t(w) %*% a1 %*% w - 2*t(a2) %*% w)/n # value of  Mallows criterion.
  list(betahat=betahat,w=w,yhat=yhat,ehat=ehat,cn=cn)
}

#' @title A function computing the  Jackknife Model Average (JMA) least-squares estimates for pure nested candimate models.
#' @description A function computing the Jackknife Model Average (JMA) least-squares estimates for pure nested candimate models.
#' @param y n×1 dependent varables
#' @param x n×p regressor matrix
#' @import quadprog
#' @importFrom stats runif rnorm
#' @return A list inluding parameter estimate, weight vector,fitted values,fitted residuals and Value of  Cross-Validation criterion.
#' @examples 
#' \dontrun{
#' y<-matrix(runif(10),nrow=10,ncol=1)
#' x<-matrix(rnorm(70),nrow=10,ncol=7)
#' MMAn(y,x)
#' }
#' @export
JMAn<-function(y,x){
  y <- as.matrix(y)
  x <- as.matrix(x)  
  n <- nrow(x)
  p <- ncol(x)
  # the selection matrix
  s <- matrix(1,nrow=p,ncol=p)
  s[upper.tri(s)] <- 0
  zero <- matrix(0,nrow=1,ncol=p)
  s <- rbind(zero,s) 
  m <- nrow(s) #the number of candimate models
  
  bbeta <- matrix(0,nrow=p,ncol=m)
  ee <- matrix(0,nrow=n,ncol=m)
  
  for (j in 1:m){
    ss <- matrix(1,nrow=n,ncol=1) %*% s[j,]
    index1 <- which(ss[,]==1)
    xs <- as.matrix(x[index1])
    xs <- matrix(xs,nrow=n,ncol=nrow(xs)/n)
    if (sum(ss)==0){
      xs <- x
      betas <- matrix(0,nrow=p,ncol=1)
      index2 <- matrix(c(1:p),nrow=p,ncol=1)  
    }  
    if (sum(ss)>0){
      betas <- solve(t(xs)%*%xs)%*%t(xs)%*%y 
      index2 <- as.matrix(which(s[j,]==1))  
    }
    beta0 <- matrix(0,nrow=p,ncol=1)
    beta0[index2] <- betas     
    bbeta[,j] <- beta0    
    
    ei <- y - xs %*% betas
    hi <- diag(xs %*% solve(t(xs) %*% xs) %*% t(xs))
    ee[,j] <- ei*(1/(1-hi))
  }
  a1 <- t(ee) %*% ee
  if (qr(a1)$rank<ncol(ee)) a1 <- a1 + diag(m)*1e-10
  a2 <- matrix(0,nrow=m,ncol=1)
  a3 <- t(rbind(matrix(1,nrow=1,ncol=m),diag(m),-diag(m)))
  a4 <- rbind(1,matrix(0,nrow=m,ncol=1),matrix(-1,nrow=m,ncol=1))
  
  w0 <- matrix(1,nrow=m,ncol=1)/m 
  w <- solve.QP(a1,a2,a3,a4,1)$solution
  w <- as.matrix(w)
  w <- w*(w>0)
  w <- w/sum(w0)
  betahat <- bbeta %*% w
  yhat <- x %*% betahat #fitting values
  ehat <- y-yhat #fitting residuals
  cn=(t(w) %*% a1 %*% w)/n #value of cross-valation criterion 
  list(betahat=betahat,w=w,yhat=yhat,ehat=ehat,cn=cn)
}

