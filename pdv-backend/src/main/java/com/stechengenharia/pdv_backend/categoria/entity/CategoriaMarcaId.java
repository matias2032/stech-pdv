package com.stechengenharia.pdv_backend.categoria.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoriaMarcaId implements Serializable {
    
    private Integer idCategoria;
    private Integer idMarca;
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        CategoriaMarcaId that = (CategoriaMarcaId) o;
        return Objects.equals(idCategoria, that.idCategoria) && 
               Objects.equals(idMarca, that.idMarca);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(idCategoria, idMarca);
    }
}