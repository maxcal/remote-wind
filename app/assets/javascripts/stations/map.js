$(document).ready(function(){

    var apiLoaded = jQuery.Deferred();
    var mapInit = jQuery.Deferred();
    var $map_canvas = $('#map_canvas');

    google.load("maps", "3", { other_params:'sensor=false', callback: function(){
        apiLoaded.resolve(google);
    }});

    // Initialize map
    apiLoaded.done(function(gmaps){
        var $controls = $map_canvas.find('.controls').clone();
        var carta;

        $map_canvas.empty();

        // poll for window size changes and resize map
        if ($map_canvas.hasClass("fullscreen")) {
            // cause binding a handler to window resize causes performance problems
            $map_canvas.height($(window).innerHeight() - 45);
            window.setInterval(function(){
                $map_canvas.height($(window).innerHeight() - 45);
            }, 800);

        }

        carta = new google.maps.Map($map_canvas[0],{
            center: new google.maps.LatLng(63.399313, 13.082236),
            zoom: 10,
            mapTypeId: google.maps.MapTypeId.ROADMAP
        });

        // Bounds fitting all the stations in view


        if ($map_canvas.hasClass("cluster")) {
            carta.markerCluster = new MarkerClusterer(carta);
        }

        if ($controls.length) {
            $map_canvas.trigger('map.add_controls', [carta, $controls]);
        }

        // uses data on map to set position if available
        carta.default_latlng = (function(data){
            return (data.lat && data.lon) ? new google.maps.LatLng(data.lat, data.lon) : false;
        }($map_canvas.data()));

        if (carta.default_latlng) {
            carta.setCenter(carta.default_latlng);
            carta.setZoom(10);
        }

        carta.removeMarkers = function(){
            if (this.markerCluster) this.markerCluster.removeMarkers(this);
        };


        mapInit.resolve(carta);
    });

    function Label(opt_options) {
        // Initialization
        jQuery.extend(this, opt_options || {});

        this.setValues(opt_options);
        // Label specific
        this.span_ = document.createElement('div');
        this.span_.setAttribute('class', 'map-label-inner');
        this.div_ = document.createElement('div');
        this.div_.setAttribute('class', 'map-label-outer');
        this.div_.appendChild(this.span_);
        this.div_.style.cssText = 'position: absolute; display: none';
    }

    mapInit.done(function(map){
        Label.prototype = jQuery.extend(new google.maps.OverlayView, {
            onAdd : function() {
                var label = this;
                this.getPanes().overlayLayer.appendChild(this.div_);
                // Ensures the label is redrawn if the text or position is changed.
                this.listeners_ = [
                    google.maps.event.addListener(this, 'position_changed',
                        function() { label.draw(); }),
                    google.maps.event.addListener(this, 'text_changed',
                        function() { label.draw(); })
                ];
            },
            onRemove : function() {
                this.div_.parentNode.removeChild(this.div_);

                for (var i = 0, I = this.listeners_.length; i < I; ++i) {
                    google.maps.event.removeListener(this.listeners_[i]);
                }
            },
            draw : function() {
                var position = this.getProjection().fromLatLngToDivPixel(this.get('position'));
                this.div_.style.left = position.x + 'px';
                this.div_.style.top = position.y + 'px';
                this.div_.style.display = 'block';
                this.span_.innerHTML = this.get('text').toString();
            }
        });
    });

    function stationMarkerFactory(station, observation) {
        var marker, options = {
            position: new google.maps.LatLng(station.latitude, station.longitude),
            title: station.name,
            href: station.path,
            zIndex: 50
        };
        if (station.offline) {
            options.icon = remotewind.icons.station_down();
        } else {
            options.icon = remotewind.icons.station(observation);
        }
        marker = new google.maps.Marker( options );
        google.maps.event.addListener(marker, 'click', function(){
            if (marker.href) window.location = marker.href;
            return false;
        });
        return marker;
    }

    $map_canvas.on('map.add_controls', function(event, map, $controls){
        map.controls[google.maps.ControlPosition.LEFT_TOP].push($controls[0]);
        google.maps.event.addDomListener($controls[0], 'click', function(e) {
            map.fitBounds(map.stations_bounds);
            e.preventDefault();
        });
    });

    // When statations are loaded do:
    jQuery(document).on('stations.loaded', function(e, stations){
        mapInit.done(function(map){
            var markers;
            var bounds = new google.maps.LatLngBounds();
            map.removeMarkers();
            markers = jQuery.map(stations, function(station){
                var marker, label;
                var observation =  station.observations[station.observations.length - 1];

                marker = stationMarkerFactory(station, observation);
                label = new Label({
                    map: map,
                    text: (function (station) {
                        var str = station.name + "<br>";
                        if (station.offline) {
                            str += " Offline";
                        } else if (observation) {
                            str += observation.speed + "(" + observation.min_wind_speed + "-" + observation.max_wind_speed + ")  m/s";
                        }
                        return str;
                    }(station))
                });

                if (map.markerCluster) {
                    map.markerCluster.addMarker(marker);
                } else {
                    marker.setMap(map);
                }

                bounds.extend(marker.position);
                label.bindTo('position', marker, 'position');
                return marker;
            });

            map.fitBounds(bounds);


            return {
                markers: markers,
                map: map
            }
        });
    });

    if ($map_canvas.length) {
        $(document).trigger('load.stations');
    }
});