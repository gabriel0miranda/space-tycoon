return function(linearAcc, strafeAcc, angularAcc)
  return {
    linearAcceleration = linearAcc or 800,
    strafeAcceleration = strafeAcc or 600,
    angularAcceleration = angularAcc or 1200,
  }
end
