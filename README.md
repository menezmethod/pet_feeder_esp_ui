# Pet Feeder Control

Pet Feeder Control is a Flutter application that allows you to control a pet feeder via MQTT. The application provides features to feed pets manually and schedule feeding times.

## Features

- **Manual Feeding**: Feed your pets instantly with a simple button press.
- **Scheduling**: Set and manage feeding schedules.
- **MQTT Integration**: Connects to an MQTT broker to control the pet feeder and retrieve status updates.
- **Custom Time Picker**: A custom time picker for setting feeding schedules.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- Flutter SDK: [Install Flutter](https://flutter.dev/docs/get-started/install)
- MQTT Broker: Ensure you have an MQTT broker running (e.g., Mosquitto).

### Installing

1. **Clone the repository**
    ```bash
    git clone https://github.com/menezmethod/pet-feeder-control.git
    cd pet-feeder-control
    ```

2. **Install dependencies**
    ```bash
    flutter pub get
    ```

3. **Run the application**
    ```bash
    flutter run
    ```

## Project Structure

- `lib/main.dart`: Entry point of the application.
- `lib/mqtt_service.dart`: Contains the `MqttService` class responsible for MQTT connectivity and operations.
- `lib/models/schedule.dart`: Contains the `Schedule` model class.
- `lib/widgets/custom_time_picker.dart`: Contains the `CustomTimePicker` widget for selecting times.

## MQTT Topics

- `feeder/feed`: Publish to this topic to feed the pets immediately.
- `feeder/schedule`: Publish updated schedules to this topic.
- `feeder/get_schedule`: Publish to this topic to request the current schedule.
- `feeder/schedule_status`: Subscribed to this topic to receive the current schedule status.

## Easy Localization 
 Enter below code for regenerate `locale_keys.g.dart` file

 `flutter pub run easy_localization:generate -S ./assets/translations -O  ./lib/  -f keys -o locale_keys.g.dart`


## Usage

### Manual Feeding

1. Open the app.
2. Press the large pet icon button in the center of the screen.

### Scheduling Feeding

1. Toggle the "Enable Scheduling" switch to enable or disable scheduling.
2. Set feeding times by tapping on the listed schedules and selecting a time using the custom time picker.
3. Toggle the switches next to each schedule to enable or disable individual feeding times.

## Customization

- **MQTT Broker Configuration**: Update the MQTT broker address and port in `lib/main.dart` when initializing the `MqttService`.
- **UI Customization**: Modify the UI by editing the widget tree in `lib/main.dart`.

## Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/awesome-feature`).
3. Commit your changes (`git commit -m 'Add some awesome feature'`).
4. Push to the branch (`git push origin feature/awesome-feature`).
5. Open a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- Thanks to the Flutter team for their amazing framework.
- Thanks to the MQTT community for their robust protocol and tools.

