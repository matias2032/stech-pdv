package com.stechengenharia.pdv_backend.cliente.sync;

import com.stechengenharia.pdv_backend.cliente.sync.ClienteSyncDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ClienteSyncCloudService {

    private final CloudClienteRepository clienteRepository;

    @Transactional
    public void aplicarLote(List<ClienteSyncDTO> dtos) {
        for (ClienteSyncDTO dto : dtos) {
            CloudClienteEntity cloud = clienteRepository.findById(dto.idCliente())
                    .orElse(new CloudClienteEntity());

            if (cloud.getVersion() != null && dto.version() < cloud.getVersion()) {
                log.warn("[Cloud Cliente] Conflito versão id={} — ignorado", dto.idCliente());
                continue;
            }

            cloud.setIdCliente(dto.idCliente());
            cloud.setDeleted("PENDING_DELETE".equals(dto.syncStatus()) || dto.deleted());

            if (!"PENDING_DELETE".equals(dto.syncStatus())) {
                cloud.setNome(dto.nome());
                cloud.setApelido(dto.apelido());
                cloud.setEmail(dto.email());
                cloud.setNuit(dto.nuit());
                cloud.setContacto(dto.contacto());
                cloud.setMorada(dto.morada());
                cloud.setIdPerfil(dto.idPerfil());
            }

            cloud.setVersion(dto.version());
            cloud.setSyncStatus("SYNCED");
            cloud.setUpdatedAt(dto.updatedAt());
            clienteRepository.save(cloud);
        }
    }

    @Transactional(readOnly = true)
    public List<ClienteSyncDTO> listarDesde(Instant since) {
        return clienteRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(c -> new ClienteSyncDTO(
                        c.getIdCliente(), c.getNome(), c.getApelido(),
                        c.getEmail(), c.getNuit(), c.getContacto(), c.getMorada(),
                        c.getIdPerfil(), c.getSyncStatus(),
                        c.isDeleted(), c.getVersion(), c.getUpdatedAt()))
                .toList();
    }
}