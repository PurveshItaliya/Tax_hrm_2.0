enum FaceProcessState {
  idle,
  initializing,
  detectingFace,
  faceDetected,
  checkingLiveness,
  recognizing,
  faceMatched,
  waitingForConfirmation,
  punching,
  success,
  failed
}

enum FaceErrorReason {
  none,
  noFace,
  multipleFaces,
  poorQuality,
  moveCloser,
  moveBack,
  straightenFace,
  livenessFailed,
  spoofDetected,
  mismatch,
  templateMissing,
  cameraDenied,
  cameraUnavailable,
  modelInitFailed,
  storageFailure,
  cancelled,
  unexpected
}
