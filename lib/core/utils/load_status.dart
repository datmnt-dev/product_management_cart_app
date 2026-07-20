/// Async load lifecycle for Firestore-backed controllers.
enum LoadStatus {
  /// Not watching (signed out).
  idle,

  /// Subscription started; waiting for first event.
  loading,

  /// Stream delivered data successfully.
  ready,

  /// Stream failed; use [retry] on the controller.
  error,
}
