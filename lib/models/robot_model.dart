class RobotModel {

  String name;

  String id;

  bool online;

  int battery;

  bool cleaning;

  double runtime;

  int cleanedPanels;

  RobotModel({

    required this.name,

    required this.id,

    required this.online,

    required this.battery,

    required this.cleaning,

    required this.runtime,

    required this.cleanedPanels,

  });

}