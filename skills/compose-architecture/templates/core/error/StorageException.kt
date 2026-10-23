package com.example.core.error

/** Expected local IO or database constraint failure, wrapped at the data-source boundary. */
class StorageException(cause: Throwable) : Exception("storage failure", cause)

/** Maps a recoverable local failure without disguising programming defects. */
fun StorageException.toAppError(): AppError = AppError(AppErrorType.Storage)
