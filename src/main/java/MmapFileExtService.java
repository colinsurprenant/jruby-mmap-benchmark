import java.io.IOException;

import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

public class MmapFileExtService implements BasicLibraryService {
  public boolean basicLoad(final Ruby runtime) throws IOException {
    new com.colinsurprenant.MmapFileExtLibrary().load(runtime, false);
    return true;
  }
}
