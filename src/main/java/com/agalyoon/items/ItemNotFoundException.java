package com.agalyoon.items;

public class ItemNotFoundException extends RuntimeException {
    public ItemNotFoundException(long id) {
        super("Item " + id + " was not found");
    }
}
