function mm = mmInit
% mmInit Start MM2
import org.micromanager.internal.MMStudio;
mm = MMStudio(false);
% Wait for mm to load
mm.core().waitForSystem();
% Try loading the proper config file
try
    mm.core().loadSystemConfiguration('C:\Users\Administrator\Documents\MMConfig-axioplan.cfg');
    mm.core().setProperty('XYStage', 'StepSize', 0.05);
    mm.core().setProperty('ZeissHalogenLamp', 'State', true);
    mm.core().setProperty('DObjective', 'Label', '10x');
    mm.core().setChannelGroup('Reflector');
catch e
    mm.core().loadSystemConfiguration('C:\Users\Administrator\Documents\MMConfig-axioplan-demo.cfg');
    mm.core().setChannelGroup('Reflector');
end
% Set presets
% Reload gui
mm.refreshGUI();
mm.showPositionList();

end