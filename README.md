# Farming Simulator Telemetry

![GitHub code size](https://img.shields.io/github/languages/code-size/marciel032/FarmingSimulatorTelemetry?style=for-the-badge)
![GitHub forks](https://img.shields.io/github/forks/marciel032/FarmingSimulatorTelemetry?style=for-the-badge)
![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/marciel032/farmingsimulatortelemetry?style=for-the-badge)
![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/marciel032/farmingsimulatortelemetry?style=for-the-badge)
![GitHub contributors](https://img.shields.io/github/contributors/marciel032/farmingsimulatortelemetry?style=for-the-badge)


> This mod allows reading data from farming simulator vehicles

### Adjustments and improvements

The project is still under development and future updates will focus on the following tasks:

- [x] Support to FS19.
- [ ] Support to FS22.
- [x] Read control cruise data.
- [ ] Read buy and sell price from vehicle.
- [ ] Create field indicate if is in vehicle
- [ ] Improve de mod icon

## 💻 Prerequisites

Before starting, make sure you have met the following requirements:
* Use Visual studio 2019 to compile the Demo.

## 🚀 Installing

Put mod telemetry in farming mods folder.
When game is running, the mod will write files about telemetry on farming install folder.

## ☕ Using

Start the telemetry reader, passing by parameter de farming install folder
```csharp
var telemetryReader = new FSTelemetryReader(@"Folder where Farming simulator is installed");
telemetryReader.OnTelemetryRead += TelemetryReader_OnTelemetryRead;
telemetryReader.Start();
```

The event OnTelemetryRead is called on new information is writed on telemetry files
```csharp
private void TelemetryReader_OnTelemetryRead(FSTelemetry telemetry)
{
    ...
}
```

## 💾 Current data available

### Vehicle
* Name 
* Wear 
* OperationTime 
* Speed 
* FuelMax 
* Fuel 
* RPMMax 
* RPM 
* IsEngineStarted 
* Gear 
* IsLightOn 
* IsHighLightOn 
* IsLightTurnRightOn 
* IsLightTurnLeftOn 
* IsLightHazardOn
* IsWiperOn
* IsCruiseControlOn
* CruiseControlSpeed
* CruiseControlMaxSpeed
* IsHandBreakeOn

### Game
* Money
* TemperatureMin
* TemperatureMax
* TemperatureTrend
* DayTime

## 📫 Contributing to the project
To contribute, follow these steps:

1. Fork this repository.
2. Create a branch.
3. Make your changes and commit them.
4. Send to original branch.
5. Create the pull request.

Alternatively, see the GitHub documentation at [how to create a pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request).


## 🤝 Colaboradores

We thank the following people who contributed to this project:

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/Marciel032">
        <img src="https://avatars3.githubusercontent.com/Marciel032" width="100px;" alt="Marciel Grützmann"/><br>
        <sub>
          <b>Marciel Grützmann</b>
        </sub>
      </a>
    </td>    
  </tr>
</table>

### 📘 Giants [SDK](https://gdn.giants-software.com/documentation.php)
