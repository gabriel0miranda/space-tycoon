return function(linearAcc, strafeAcc, angularAcc, linearDamping)
  return {
    linearAcceleration = linearAcc or 800,
    strafeAcceleration = strafeAcc or 600,
    angularAcceleration = angularAcc or 1200,
    linearDamping       = linearDamping       or 0.2,
  }
end
