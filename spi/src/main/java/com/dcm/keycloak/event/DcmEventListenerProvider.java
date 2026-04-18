package com.dcm.keycloak.event;

import org.jboss.logging.Logger;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;

/**
 * ตัวอย่าง Event Listener SPI
 * รับ event จาก Keycloak เช่น LOGIN, LOGIN_ERROR, LOGOUT
 *
 * เพิ่ม use case ได้ เช่น:
 * - ส่ง webhook ไปยัง service อื่น
 * - บันทึก audit log ลง database
 * - แจ้งเตือนเมื่อ login ผิดหลายครั้ง
 */
public class DcmEventListenerProvider implements EventListenerProvider {

    private static final Logger log = Logger.getLogger(DcmEventListenerProvider.class);

    @Override
    public void onEvent(Event event) {
        if (event.getType() == EventType.LOGIN) {
            log.infof("[DCM] LOGIN: userId=%s, realm=%s, clientId=%s, ip=%s",
                    event.getUserId(),
                    event.getRealmId(),
                    event.getClientId(),
                    event.getIpAddress());
        }

        if (event.getType() == EventType.LOGIN_ERROR) {
            log.warnf("[DCM] LOGIN_ERROR: error=%s, realm=%s, ip=%s",
                    event.getError(),
                    event.getRealmId(),
                    event.getIpAddress());
        }

        if (event.getType() == EventType.LOGOUT) {
            log.infof("[DCM] LOGOUT: userId=%s, realm=%s",
                    event.getUserId(),
                    event.getRealmId());
        }
    }

    @Override
    public void onEvent(AdminEvent adminEvent, boolean includeRepresentation) {
        log.debugf("[DCM] ADMIN_EVENT: operation=%s, resourceType=%s, realm=%s",
                adminEvent.getOperationType(),
                adminEvent.getResourceType(),
                adminEvent.getRealmId());
    }

    @Override
    public void close() {
        // ไม่มี resource ที่ต้อง close
    }
}
