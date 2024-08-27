import '../typings/shims.d.ts';
import * as Turbo from '@hotwired/turbo';
import TurboPower from 'turbo_power';
import { registerDialogStreamAction } from './dialog-stream-action';
import { addTurboEventListeners } from './turbo-event-listeners';
import { registerFlashStreamAction } from './flash-stream-action';
import { addTurboGlobalListeners } from './turbo-global-listeners';

Turbo.session.drive = true;
Turbo.setProgressBarDelay(100);

// Start turbo
Turbo.start();

// Register our own actions
addTurboEventListeners();
addTurboGlobalListeners();
registerDialogStreamAction();
registerFlashStreamAction();

// Register turbo power actions
TurboPower.initialize(Turbo.StreamActions);

// Error handling when "Content missing" returned
document.addEventListener('turbo:frame-missing', (event:CustomEvent) => {
  const { detail: { response, visit } } = event as { detail:{ response:Response, visit:(url:string) => void } };
  event.preventDefault();
  visit(response.url);
});
