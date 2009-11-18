﻿package com.longtailvideo.jwplayer.media {
	import com.longtailvideo.jwplayer.events.MediaEvent;
	import com.longtailvideo.jwplayer.model.PlayerConfig;
	import com.longtailvideo.jwplayer.model.PlaylistItem;
	import com.longtailvideo.jwplayer.player.PlayerState;
	import com.longtailvideo.jwplayer.utils.NetClient;

	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.utils.*;


	/**
	 * Wrapper for playback of progressively downloaded _video.
	 **/
	public class VideoMediaProvider extends MediaProvider {
		/** Video object to be instantiated. **/
		protected var _video:Video;
		/** NetConnection object for setup of the video _stream. **/
		protected var _connection:NetConnection;
		/** NetStream instance that handles the stream IO. **/
		protected var _stream:NetStream;
		/** Sound control object. **/
		protected var _transformer:SoundTransform;
		/** ID for the position interval. **/
		protected var _positionInterval:Number;
		/** Load offset for bandwidth checking. **/
		protected var _loadTimer:Number;


		/** Constructor; sets up the connection and display. **/
		public function VideoMediaProvider() {
			super('video');
		}


		public override function initializeMediaProvider(cfg:PlayerConfig):void {
			super.initializeMediaProvider(cfg);
			_connection = new NetConnection();
			_connection.connect(null);
			_stream = new NetStream(_connection);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
			_stream.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
			_stream.bufferTime = config.bufferlength;
			_stream.client = new NetClient(this);
			_video = new Video(320, 240);
			_video.smoothing = config.smoothing;
			_video.attachNetStream(_stream);
			_transformer = new SoundTransform();
		}


		/** Catch security errors. **/
		protected function errorHandler(evt:ErrorEvent):void {
			error(evt.text);
		}


		/** Load content. **/
		override public function load(itm:PlaylistItem):void {
			if (_item != itm || _stream.bytesLoaded == 0) {
				_item = itm;
				media = _video;
				_stream.checkPolicyFile = true;
				_stream.play(item.file);
			} else {
				seek(0);
			}
			_positionInterval = setInterval(positionHandler, 200);
			_loadTimer = setTimeout(loadTimerComplete, 3000);
			setState(PlayerState.BUFFERING);
			sendBufferEvent(0);
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_LOADED);
			config.mute == true ? setVolume(0) : setVolume(config.volume);
		}


		/** timeout for checking the bitrate. **/
		protected function loadTimerComplete():void {
			var obj:Object = new Object();
			obj.bandwidth = Math.round(_stream.bytesLoaded / 1024 / 3 * 8);
			if (item.duration) {
				obj.bitrate = Math.round(_stream.bytesTotal / 1024 * 8 / item.duration);
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: obj});
		}


		/** Get metadata information from netstream class. **/
		public function onData(dat:Object):void {
			if (dat.width) {
				_video.width = dat.width;
				_video.height = dat.height;
				resize(_width, _height);
			}
			if (dat.duration) {
				_item.duration = dat.duration;
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: dat});
		}


		/** Pause playback. **/
		override public function pause():void {
			_stream.pause();
			super.pause();
		}


		/** Resume playing. **/
		override public function play():void {
			if (!_positionInterval) {
				_positionInterval = setInterval(positionHandler, 100);
			}
			_stream.resume();
			super.play();
		}


		/** Interval for the position progress **/
		protected function positionHandler():void {
			_position = Math.round(_stream.time * 10) / 10;
			var bufferPercent:Number = _stream.bytesLoaded / _stream.bytesTotal * 100;
			var bufferTime:Number = _stream.bufferTime < (item.duration - position) ? _stream.bufferTime : (item.duration - position);
			var bufferFill:Number = _stream.bufferTime == 0 ? 0 : Math.ceil(_stream.bufferLength / bufferTime * 100);

			if (bufferFill < 25 && state == PlayerState.PLAYING) {
				_stream.pause();
				setState(PlayerState.BUFFERING);
			} else if (bufferFill > 95 && state == PlayerState.BUFFERING) {
				sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_BUFFER_FULL);
			}

			if (state == PlayerState.BUFFERING) {
				sendBufferEvent(bufferPercent);
			} else if (position < item.duration) {
				if (state == PlayerState.PLAYING && _position >= 0) {
					sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {position: position, duration: item.duration, bufferPercent: bufferPercent});
				}
			} else if (item.duration > 0) {
				complete();
			}
		}


		/** Seek to a new position. **/
		override public function seek(pos:Number):void {
			var bufferLength:Number = _stream.bytesLoaded / _stream.bytesTotal * item.duration;
			if (pos <= bufferLength) {
				super.seek(pos);
				clearInterval(_positionInterval);
				_positionInterval = undefined;
				_stream.seek(position);
				play();
			}
		}


		/** Receive NetStream status updates. **/
		protected function statusHandler(evt:NetStatusEvent):void {
			switch (evt.info.code) {
				case "NetStream.Play.Stop":
					complete();
					break;
				case "NetStream.Play.StreamNotFound":
					error('Video not found or access denied: ' + item.file);
					break;
			}
			sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, {metadata: {status: evt.info.code}});
		}


		/** Destroy the video. **/
		override public function stop():void {
			if (_stream.bytesLoaded < _stream.bytesTotal) {
				_stream.close();
			} else {
				_stream.pause();
				_stream.seek(0);
			}
			_loadTimer = undefined;
			clearInterval(_positionInterval);
			_positionInterval = undefined;
			super.stop();
		}


		/** Set the volume level. **/
		override public function setVolume(vol:Number):void {
			_transformer.volume = vol / 100;
			_stream.soundTransform = _transformer;
			super.setVolume(vol);
		}
	}
}
