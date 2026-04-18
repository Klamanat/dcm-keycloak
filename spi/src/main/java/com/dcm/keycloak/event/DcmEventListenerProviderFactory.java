package com.dcm.keycloak.event;

import org.keycloak.Config;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventListenerProviderFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;

public class DcmEventListenerProviderFactory implements EventListenerProviderFactory {

    // ID นี้ใช้ตอนเลือก Event Listener ใน Admin Console → Events → Event listeners
    public static final String PROVIDER_ID = "dcm-event-listener";

    @Override
    public EventListenerProvider create(KeycloakSession session) {
        return new DcmEventListenerProvider();
    }

    @Override
    public void init(Config.Scope config) {
        // อ่าน config จาก keycloak.conf ได้ถ้าต้องการ
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
    }

    @Override
    public void close() {
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
