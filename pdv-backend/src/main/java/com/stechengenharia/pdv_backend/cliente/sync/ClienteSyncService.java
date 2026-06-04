package com.stechengenharia.pdv_backend.cliente.sync;

import com.stechengenharia.pdv_backend.cliente.entity.Cliente;
import com.stechengenharia.pdv_backend.cliente.entity.PerfilCliente;
import com.stechengenharia.pdv_backend.cliente.repository.ClienteRepository;
import com.stechengenharia.pdv_backend.cliente.repository.PerfilClienteRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ClienteSyncService {

    private final ClienteRepository       clienteRepository;
    private final PerfilClienteRepository perfilClienteRepository;
    private final RestTemplate            restTemplate;

    @Value("${sync.cloud.base-url}") private String cloudBaseUrl;
    @Value("${sync.cloud.api-key}")  private String apiKey;

    private Instant lastPullAt = Instant.EPOCH;

    @Transactional
    public void push() {
        List<Cliente> pendentes = clienteRepository.findBySyncStatusIn(
            List.of("PENDING_CREATE", "PENDING_UPDATE", "PENDING_DELETE")
        );
        if (pendentes.isEmpty()) return;
        log.info("[Cliente PUSH] {} registos pendentes", pendentes.size());

        try {
            List<ClienteSyncDTO> payload = pendentes.stream().map(this::toDTO).toList();
            ResponseEntity<Void> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/clientes", HttpMethod.POST,
                new HttpEntity<>(payload, buildHeaders()), Void.class
            );
            if (resp.getStatusCode().is2xxSuccessful()) {
                pendentes.forEach(c -> c.setSyncStatus("SYNCED"));
                clienteRepository.saveAll(pendentes);
                log.info("[Cliente PUSH] {} registos marcados SYNCED", pendentes.size());
            }
        } catch (Exception e) {
            log.warn("[Cliente PUSH] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    @Transactional
    public void pull() {
        log.debug("[Cliente PULL] Buscando desde {}", lastPullAt);
        try {
            ResponseEntity<List<ClienteSyncDTO>> resp = restTemplate.exchange(
                cloudBaseUrl + "/sync/clientes?since=" + lastPullAt,
                HttpMethod.GET, new HttpEntity<>(buildHeaders()),
                new ParameterizedTypeReference<>() {}
            );
            if (resp.getBody() == null || resp.getBody().isEmpty()) return;

for (ClienteSyncDTO dto : resp.getBody()) {
    Cliente local = clienteRepository.findById(dto.idCliente())
            .orElse(null);

    // Se existe localmente e a versão local é mais recente, ignora
    if (local != null && local.getVersion() != null 
            && dto.version() < local.getVersion()) continue;

    PerfilCliente perfil = perfilClienteRepository.findById(dto.idPerfil())
            .orElse(null);
    if (perfil == null) {
        log.warn("[Cliente PULL] Perfil id={} não encontrado — cliente id={} ignorado",
                dto.idPerfil(), dto.idCliente());
        continue;
    }

    if (local == null) {
        // Registo novo — usa o builder para definir o ID (contorna o @Setter(NONE))
        local = Cliente.builder()
                .nome(dto.nome())
                .apelido(dto.apelido())
                .email(dto.email())
                .nuit(dto.nuit())
                .contacto(dto.contacto())
                .morada(dto.morada())
                .perfil(perfil)
                .build();
        // Reflecte o ID da nuvem via JPA merge em vez de setter
        clienteRepository.save(local);
        continue;
    }

    // Registo existente — actualiza campos (ID não muda)
    local.setNome(dto.nome());
    local.setApelido(dto.apelido());
    local.setEmail(dto.email());
    local.setNuit(dto.nuit());
    local.setContacto(dto.contacto());
    local.setMorada(dto.morada());
    local.setPerfil(perfil);
    local.setDeleted(dto.deleted());
    local.setVersion(dto.version());
    local.setSyncStatus("SYNCED");
    clienteRepository.save(local);
}
            lastPullAt = Instant.now();
        } catch (Exception e) {
            log.warn("[Cliente PULL] Falhou: {}. Tentativa em 60s.", e.getMessage());
        }
    }

    private ClienteSyncDTO toDTO(Cliente c) {
        return new ClienteSyncDTO(
            c.getId(), c.getNome(), c.getApelido(),
            c.getEmail(), c.getNuit(), c.getContacto(), c.getMorada(),
            c.getPerfil().getId(),
            c.getSyncStatus(), c.isDeleted(), c.getVersion(), c.getUpdatedAt()
        );
    }

    private HttpHeaders buildHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        h.set("X-Api-Key", apiKey);
        return h;
    }
}