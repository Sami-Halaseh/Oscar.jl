########################################################################
#
# (1) AbsSpec interface
#
########################################################################

underlying_scheme(X::AffineVariety) = X.X

########################################################################
#
# (1) AbsAffineAlgebaicSet interface
#
########################################################################

fat_scheme(X::AffineVariety) = fat_scheme(underlying_scheme(X))
