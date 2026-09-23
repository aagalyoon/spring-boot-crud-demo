package com.agalyoon.items;

import java.math.BigDecimal;

public record ItemResponse(Long id, String name, String description, BigDecimal price, int quantity) {
    public static ItemResponse from(Item item) {
        return new ItemResponse(item.getId(), item.getName(), item.getDescription(),
                item.getPrice(), item.getQuantity());
    }
}
