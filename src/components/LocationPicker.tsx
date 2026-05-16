import React, { useState, useEffect, useRef } from 'react';
import { 
  APIProvider, 
  Map, 
  AdvancedMarker, 
  useMapsLibrary,
  useApiIsLoaded,
  ControlPosition,
  MapControl
} from '@vis.gl/react-google-maps';
import { MapPin, Navigation, Search, Loader2 } from 'lucide-react';

const API_KEY = 
  process.env.GOOGLE_MAPS_PLATFORM_KEY || 
  (import.meta as any).env?.VITE_GOOGLE_MAPS_PLATFORM_KEY || 
  '';

const hasValidKey = Boolean(API_KEY) && API_KEY.length > 20;

const DEFAULT_CENTER = { lat: -26.2041, lng: 28.0473 }; // Johannesburg

interface LocationPickerProps {
  onLocationSelect: (location: { address: string; lat: number; lng: number }) => void;
  initialAddress?: string;
}

const AutocompleteInput = ({ 
  address, 
  setAddress, 
  onLocationSelect, 
  setPosition 
}: { 
  address: string, 
  setAddress: (a: string) => void, 
  onLocationSelect: any,
  setPosition: (p: {lat: number, lng: number}) => void
}) => {
  const inputRef = useRef<HTMLInputElement>(null);
  const places = useMapsLibrary('places');

  useEffect(() => {
    if (!places || !inputRef.current) return;

    const options = {
      types: ['address'],
      componentRestrictions: { country: 'za' }, // South Africa
      fields: ['geometry', 'formatted_address']
    };

    const autocomplete = new places.Autocomplete(inputRef.current, options);

    autocomplete.addListener('place_changed', () => {
      const place = autocomplete.getPlace();
      if (place.geometry && place.geometry.location) {
        const lat = place.geometry.location.lat();
        const lng = place.geometry.location.lng();
        const addr = place.formatted_address || '';
        setPosition({ lat, lng });
        setAddress(addr);
        onLocationSelect({ address: addr, lat, lng });
      }
    });

    return () => {
      google.maps.event.clearInstanceListeners(autocomplete);
    };
  }, [places]);

  return (
    <div className="relative">
      <div className="absolute left-4 top-1/2 -translate-y-1/2 text-text-secondary">
        <Search size={18} />
      </div>
      <input 
        ref={inputRef}
        type="text"
        value={address}
        onChange={(e) => setAddress(e.target.value)}
        placeholder="Search for your shop address"
        className="w-full bg-card-bg border border-border-custom rounded-xl pl-11 pr-4 py-3.5 text-sm font-medium focus:ring-2 focus:ring-spaza-green outline-none transition-all text-text-primary placeholder:text-text-secondary"
      />
    </div>
  );
};

const LocationPickerContent: React.FC<LocationPickerProps> = ({ onLocationSelect, initialAddress }) => {
  const [address, setAddress] = useState(initialAddress || '');
  const [position, setPosition] = useState<{ lat: number; lng: number } | null>(null);
  const [detecting, setDetecting] = useState(false);
  const geocoding = useMapsLibrary('geocoding');
  const apiIsLoaded = useApiIsLoaded();

  const handleDetectLocation = () => {
    if ("geolocation" in navigator) {
      setDetecting(true);
      navigator.geolocation.getCurrentPosition(async (pos) => {
        const { latitude, longitude } = pos.coords;
        const newPos = { lat: latitude, lng: longitude };
        setPosition(newPos);
        
        if (geocoding) {
          try {
            const geocoder = new google.maps.Geocoder();
            const response = await geocoder.geocode({ location: newPos });
            if (response.results[0]) {
              const addr = response.results[0].formatted_address;
              setAddress(addr);
              onLocationSelect({ address: addr, lat: latitude, lng: longitude });
            }
          } catch (error) {
            console.error("Geocoding failed:", error);
          }
        }
        setDetecting(false);
      }, (error) => {
        console.error("Error detecting location:", error);
        setDetecting(false);
      });
    }
  };

  return (
    <div className="space-y-4">
      <AutocompleteInput 
        address={address}
        setAddress={setAddress}
        setPosition={setPosition}
        onLocationSelect={onLocationSelect}
      />

      <button 
        type="button"
        onClick={handleDetectLocation}
        disabled={detecting || !apiIsLoaded}
        className="w-full flex items-center justify-center gap-2 py-3 border-2 border-dashed border-spaza-green/30 text-spaza-green font-bold text-sm rounded-xl hover:bg-spaza-green/5 transition-all disabled:opacity-50"
      >
        {detecting ? <Loader2 className="animate-spin" size={18} /> : <Navigation size={18} />}
        Detect My Current Location
      </button>

      <div className="h-64 rounded-2xl overflow-hidden border border-border-custom shadow-sm relative bg-card-bg">
        {apiIsLoaded ? (
          <Map
            center={position || DEFAULT_CENTER}
            onCameraChanged={(ev) => setPosition(ev.detail.center)}
            defaultZoom={15}
            mapId="bf19a9101d7515d8"
            disableDefaultUI={true}
            internalUsageAttributionIds={['gmp_mcp_codeassist_v1_aistudio']}
          >
            {position && (
              <AdvancedMarker position={position}>
                <div className="p-2 bg-spaza-green rounded-full shadow-lg border-2 border-white">
                  <MapPin size={20} className="text-white" />
                </div>
              </AdvancedMarker>
            )}
          </Map>
        ) : (
          <div className="w-full h-full flex flex-col items-center justify-center gap-2">
            <Loader2 className="animate-spin text-spaza-green" size={24} />
            <p className="text-[10px] font-bold text-text-secondary uppercase tracking-widest">Loading Interactive Map...</p>
          </div>
        )}
      </div>
    </div>
  );
};

export const LocationPicker: React.FC<LocationPickerProps> = (props) => {
  if (!hasValidKey) {
    return (
      <div className="p-8 bg-card-bg border-2 border-dashed border-border-custom rounded-[32px] text-center space-y-4">
        <div className="w-16 h-16 bg-spaza-green/10 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <MapPin size={32} className="text-spaza-green" />
        </div>
        <h4 className="text-base font-black text-text-primary uppercase tracking-tight">Location Services Required</h4>
        <div className="space-y-4 text-left bg-spaza-bg/50 p-5 rounded-2xl border border-border-custom">
          <p className="text-[11px] font-bold text-text-secondary uppercase tracking-widest mb-2">Step 1: Get your API Key</p>
          <p className="text-xs text-text-primary leading-relaxed">
            1. Visit the <a href="https://console.cloud.google.com/google/maps-apis/start" target="_blank" rel="noopener noreferrer" className="text-spaza-green font-bold underline">Google Cloud Console</a>.
            <br />2. Enable **Maps JavaScript API**, **Places API**, and **Geocoding API**.
            <br />3. Ensure a **Billing Account** is linked (Google requires this for all Maps projects).
          </p>
          
          <p className="text-[11px] font-bold text-text-secondary uppercase tracking-widest mt-4 mb-2">Step 2: Add to SpazaLink</p>
          <p className="text-xs text-text-primary leading-relaxed">
            Open **Settings** (⚙️) → **Secrets** → Add <code className="bg-white px-1.5 py-0.5 rounded border border-border-custom text-spaza-green font-mono">GOOGLE_MAPS_PLATFORM_KEY</code>.
          </p>

          <p className="text-[11px] font-bold text-red-500 uppercase tracking-widest mt-4 mb-2">Seeing "Something went wrong"?</p>
          <p className="text-[10px] text-text-primary leading-relaxed">
            This usually means **Billing is not enabled** or the APIs from Step 1 are not yet active. It can take up to 5 minutes for activation to propagate.
          </p>
        </div>
        
        <p className="text-[10px] text-text-secondary italic">
          Note: Google Maps requires an active billing account even for the free usage tier.
        </p>
      </div>
    );
  }

  return (
    <APIProvider 
      apiKey={API_KEY}
    >
      <LocationPickerContent {...props} />
    </APIProvider>
  );
};
