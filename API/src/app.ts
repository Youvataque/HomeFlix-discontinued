import { startAPI } from './api/api.js';
import { startFolderWatcher } from './watcher/folder_watcher.js';
import { startJsonWatcher } from './watcher/json_watcher.js';
import { startSpecWatcher } from './watcher/spec_watcher.js';
import { startVpnWatcher } from './watcher/vpn_watcher.js';

/////////////////////////////////////////////////////////////////////////////////
// Main de l'api
startAPI();
startFolderWatcher();
startJsonWatcher();
startSpecWatcher();
startVpnWatcher();