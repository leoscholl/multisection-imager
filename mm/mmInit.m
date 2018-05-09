function mm = mmInit
% mmInit Start MM2
import org.micromanager.internal.MMStudio;
mm = MMStudio(false);
% Wait for mm to load
mm.core().waitForSystem();
% Set presets
try
    mm.core().setProperty('XYStage', 'StepSize', 0.05);
    mm.core().setProperty('ZeissHalogenLamp', 'State', true);
    mm.core().setProperty('DObjective', 'Label', '10x');
    mm.core().setChannelGroup('Reflector');
    % Reload gui
    mm.refreshGUI();
    mm.showPositionList();
catch
    fprintf(2, ['Error loading configuration file...\n',...
        'Is microscope, stage, and camera turned on and connected?\n',...
        'Please exit MATLAB and try again\n']);
end

end