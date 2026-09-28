package com.example.feature.notes.util

// Deliberate violation: a feature must hold only data/, domain/,
// presentation/, navigation/ and di/ — a util/ package is forbidden.
public object NotesUtil {

    public fun formatCount(count: Int): String = count.toString()
}
