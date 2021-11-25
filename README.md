# Telemetria-FarmingSimulator

#### How to install
Put mod telemetry in farming mods folder.
When game is running, the mod will write files about telemetry on farming instalation folder.

#### How to use

Start the telemetry reader, passing by parameter de farming installation folder
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
