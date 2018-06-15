function mmReload(mm)
mm.loadSystemConfiguration();
mm.core().waitForSystem();
% Set presets
mm.core().setProperty('XYStage', 'StepSize', 0.05);
mm.core().setProperty('ZeissHalogenLamp', 'State', true);
mm.core().setProperty('DObjective', 'Label', '10x');
mm.core().setChannelGroup('Reflector');
% Reload gui
mm.refreshGUI();
end