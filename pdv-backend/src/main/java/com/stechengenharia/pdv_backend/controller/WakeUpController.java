package com.stechengenharia.pdv_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

@RestController
@RequestMapping("/wake-up")
public class WakeUpController {

    @GetMapping
    public ResponseEntity<Map<String, String>> wakeUp() {
        return ResponseEntity.ok(Map.of(
            "status",    "online",
            "mensagem",  "Servidor activo e a responder.",
            "timestamp", ZonedDateTime.now()
                             .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss z"))
        ));
    }
}