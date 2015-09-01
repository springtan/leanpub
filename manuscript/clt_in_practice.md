---
title: "Central Limit Theorem in Practice"
layout: page
---






## Central Limit Theorem In Practice

Let's use our data to see how well the central limit approximates sample averages from our data. We will leverage our entire population dataset to compare the results we obtain by actually sampling from the distribution to what the CLT predicts.  




```r
dat <- read.csv("mice_pheno.csv") ##file was previously downloaded
head(dat)
```

```
##   Sex Diet Bodyweight
## 1   F   hf      31.94
## 2   F   hf      32.48
## 3   F   hf      22.82
## 4   F   hf      19.92
## 5   F   hf      32.22
## 6   F   hf      27.50
```

Start by selecting only female mice since males and females have different weights.


```r
hfPopulation <- dat[dat$Sex=="F" & dat$Diet=="hf",3]
controlPopulation <- dat[dat$Sex=="F" & dat$Diet=="chow",3]
```

We can compute the population parameters of interest using the mean function.


```r
mu_hf <- mean(hfPopulation)
mu_control <- mean(controlPopulation)
print(mu_hf - mu_control)
```

```
## [1] 2.375517
```

Compute the population standard deviations as well. Note that we do not use the R function `sd` because this is to compute the population based estimates that divide by the sample size - 1. 

We can see that with R code:

```r
x<-controlPopulation
N<-length(x)
popvar <- mean((x-mean(x))^2)
identical(var(x),popvar)
```

```
## [1] FALSE
```

```r
identical(var(x)*(N-1)/N, popvar)
```

```
## [1] TRUE
```

So to be mathematically correct we do not use `sd` or  `var`. I am going to define a function for this:

```r
popvar <- function(x) mean( (x-mean(x))^2)
popsd <- function(x) sqrt(popvar(x)) 
```

Now we can compute the population SD:


```r
sd_hf <- popsd(hfPopulation)
sd_control <- popsd(controlPopulation)
```

Remember that in practice we do not get to compute these population parameters.
These are values we do not get to see. In general, we want to estimate them from samples. 

```r
N <- 12
hf <- sample(hfPopulation,12)
control <- sample(controlPopulation,12)
```
The CLT tells us that, for large {$$}N{/$$}, each of these is approximately normal with average population mean and standard error population variance divided by {$$}N{/$$}. We mentioned that a rule of thumb is that {$$}N{/$$} should be 30 or more. But that is just a rule of thumb as the preciseness of the approximation depends on the population distribution. Here we can actually check the approximation and we do that for various values of {$$}N{/$$}.

Now we use `sapply` and `replicate` instead of `for` loops, which is recommended.

```r
Ns <- c(3,12,25,50)
B <- 10000 #number of simulations
res <-  sapply(Ns,function(n){
  replicate(B,mean(sample(hfPopulation,n))-mean(sample(controlPopulation,n)))
})
```

Now we can use qq-plots to see how well CLT approximations works for these. If in fact the normal distribution is a good approximation, the points should fall on a straight line when compared to normal quantiles. The more it deviates, the worse the approximation. We also show, in the title, the average and SD of the observed distribution which demonstrates how the SD decreases with {$$}\sqrt{N}{/$$} as predicted. 


```r
library(rafalib)
```

```
## 
## Attaching package: 'rafalib'
## 
## The following objects are masked _by_ '.GlobalEnv':
## 
##     popsd, popvar
```

```r
mypar(2,2)
for(i in seq(along=Ns)){
  title <- paste("N=",Ns[i],"Avg=",signif(mean(res[,i]),3),"SD=",signif(popsd(res[,i]),3)) ##popsd defined above
  qqnorm(res[,i],main=title)
  qqline(res[,i],col=2)
}
```

![Quantile versus quantile plot of simulated differences versus theoretical normal distribution for four different sample sizes.](images/R/clt_in_practice-effect_size_qqplot-1.png) 

Here we see a pretty good fit even for 3. Why is this? Because the population itself is relatively close to normally distributed, the averages are close to normal as well (the sum of normals is normals). In practice we actually calculate a ratio: we divide by the estimated standard deviation. Here is where the sample size starts to matter more.


```r
Ns <- c(3,12,25,50)
B <- 10000 #number of simulations
##function to compute a t-stat
computetstat <- function(n){
  y<-sample(hfPopulation,n)
  x<-sample(controlPopulation,n)
  (mean(y)-mean(x))/sqrt(var(y)/n+var(x)/n)
}
res <-  sapply(Ns,function(n){
  replicate(B,computetstat(n))
})
mypar(2,2)
for(i in seq(along=Ns)){
  qqnorm(res[,i],main=Ns[i])
  qqline(res[,i],col=2)
}
```

![Quantile versus quantile plot of simulated ratios versus theoretical normal distribution for four different sample sizes.](images/R/clt_in_practice-t_test_qqplot-1.png) 

So we see that for {$$}N=3{/$$} the CLT does not provide a usable approximation. For {$$}N=12{/$$} there is a slight deviation at the higher values, although the approximation appears useful. For 25 and 50 the approximation is spot on. 

This simulation only proves that {$$}N=12{/$$} is large enough in this case, not in general. As mentioned above, we will not be able to perform this simulation in most situations. We only use the simulation to illustrate the concepts behind the CLT. In future sections we will describe the approaches we actually use in practice.





