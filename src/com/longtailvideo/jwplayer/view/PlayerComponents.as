package com.longtailvideo.jwplayer.view {
	import com.longtailvideo.jwplayer.model.PlayerConfig;
	import com.longtailvideo.jwplayer.player.Player;
	import com.longtailvideo.jwplayer.plugins.PluginConfig;
	import com.longtailvideo.jwplayer.view.components.ControlbarComponent;
	import com.longtailvideo.jwplayer.view.components.ControlbarComponentV4;
	import com.longtailvideo.jwplayer.view.components.DisplayComponent;
	import com.longtailvideo.jwplayer.view.components.DockComponent;
	import com.longtailvideo.jwplayer.view.components.PlaylistComponent;
	import com.longtailvideo.jwplayer.view.interfaces.IControlbarComponent;
	import com.longtailvideo.jwplayer.view.interfaces.IDisplayComponent;
	import com.longtailvideo.jwplayer.view.interfaces.IDockComponent;
	import com.longtailvideo.jwplayer.view.interfaces.IPlayerComponent;
	import com.longtailvideo.jwplayer.view.interfaces.IPlaylistComponent;
	import com.longtailvideo.jwplayer.view.interfaces.ISkin;
	import com.longtailvideo.jwplayer.view.skins.SWFSkin;
	
	
	public class PlayerComponents {
		private var _controlbar:IControlbarComponent;
		private var _display:IDisplayComponent;
		private var _dock:IDockComponent;
		private var _playlist:IPlaylistComponent;
		private var _config:PlayerConfig;
		private var _skin:ISkin;
		
		private var _player:Player;
		
		
		public function PlayerComponents(player:Player) {
			_player = player;
			_skin = player.skin;
			_config = player.config;
			
			if (_skin is SWFSkin) {
				_controlbar = new ControlbarComponentV4(_player);
			} else {
				_controlbar = new ControlbarComponent(_player);
			}
			_display = new DisplayComponent(_player);
			_playlist = new PlaylistComponent(_player);
			_dock = new DockComponent(_player);
		}
		
		
		public function get controlbar():IControlbarComponent {
			return _controlbar;
		}
		
		
		public function get display():IDisplayComponent {
			return _display;
		}
		
		
		public function get dock():IDockComponent {
			return _dock;
		}
		
		
		public function get playlist():IPlaylistComponent {
			return _playlist;
		}
		
		
		private function set controlbar(bar:IControlbarComponent):void {
			_controlbar = bar;
		}
		
		public function resize(width:Number, height:Number):void {
			resizeComponent(_display, _config.pluginConfig('display'));
			resizeComponent(_controlbar, _config.pluginConfig('controlbar'));
			resizeComponent(_playlist, _config.pluginConfig('playlist'));
		}
		
		private function resizeComponent(comp:IPlayerComponent, config:PluginConfig):void {
			comp.resize(config['width'], config['height']);
			comp.x = config['x'];
			comp.y = config['y'];
		}
	}
}