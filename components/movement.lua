return function(linearAcc, strafeAcc, angularAcc, linearDamping, angularDampingFactor)
  return {
    linearAcceleration = linearAcc or 800,
    strafeAcceleration = strafeAcc or 600,
    angularAcceleration = angularAcc or 1200,
    linearDamping       = linearDamping       or 0.2,
    angularDampingFactor= angularDampingFactor or 0.4
  }
end
