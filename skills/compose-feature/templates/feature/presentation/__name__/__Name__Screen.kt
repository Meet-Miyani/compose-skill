/**
 * Stateless content for the __Name__ destination in the Notes example.
 *
 * Renders state only. No ViewModel, no Koin, no state reads beyond params.
 * Every UiState field is read below; string literals are SEAMs to extract
 * to resources before done (the compose-ui skill owns string resources).
 */
package __PACKAGE__.presentation.__name__

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
fun __Name__Screen(
    state: __Name__UiState,
    onTitleChange: (String) -> Unit,
    onSave: () -> Unit,
    onRetry: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    when {
        state.isLoading -> CircularProgressIndicator(modifier = modifier)
        state.error != null && state.items.isEmpty() -> Column(modifier = modifier) {
            Text("Something went wrong.") // SEAM: string resource
            Button(onClick = onRetry) { Text("Retry") } // SEAM: string resource
            Button(onClick = onBack) { Text("Back") } // SEAM: string resource
        }
        state.isMissing -> Column(modifier = modifier) {
            Text("This note no longer exists.") // SEAM: string resource
            Button(onClick = onBack) { Text("Back") } // SEAM: string resource
        }
        else -> Column(modifier = modifier) {
            if (state.isRefreshing) {
                Text("Refreshing…") // SEAM: string resource
            }
            state.items.forEach { item -> Text(item.title ?: "") }
            OutlinedTextField(
                value = state.draftTitle,
                onValueChange = onTitleChange,
            )
            Button(onClick = onSave) { Text("Save") } // SEAM: string resource
            Button(onClick = onBack) { Text("Back") } // SEAM: string resource
        }
    }
}
