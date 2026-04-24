enum AdminEdgeMaintenanceAction {
  pushDispatch,
  purgeTempUploads;

  String get functionName {
    switch (this) {
      case AdminEdgeMaintenanceAction.pushDispatch:
        return 'push-dispatch';
      case AdminEdgeMaintenanceAction.purgeTempUploads:
        return 'purge-temp-uploads';
    }
  }
}
