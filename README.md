# Farming Simulator Telemetry

![GitHub code size](https://img.shields.io/github/languages/code-size/marciel032/FarmingSimulatorTelemetry?style=for-the-badge)
![GitHub forks](https://img.shields.io/github/forks/marciel032/FarmingSimulatorTelemetry?style=for-the-badge)
![Bitbucket open issues](https://img.shields.io/bitbucket/issues/marciel032/FarmingSimulatorTelemetry?style=for-the-badge)
![Bitbucket open pull requests](https://img.shields.io/bitbucket/pr-raw/marciel032/FarmingSimulatorTelemetry?style=for-the-badge)


> This mod allows reading data from farming simulator vehicles

### Adjustments and improvements

The project is still under development and future updates will focus on the following tasks:

- [x] Support to FS19.
- [ ] Support to FS22.
- [ ] Read control cruise data.
- [ ] Read buy and sell price from vehicle.

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

### 📘 Giants [SDK](https://gdn.giants-software.com/documentation.php)


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
