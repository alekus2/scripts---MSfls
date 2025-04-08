custom_theme <- theme_bw() +
  theme(axis.text.x = element_text(vjust = 0.5, hjust = 0.5, size = 5, color = "black"),
        axis.title = element_text(face = "bold", size = 10, color = "black"),
        axis.text.y = element_text(vjust = 0.5, hjust = 0.5, size = 5, color = "black"),
        plot.title = element_text(hjust = 0.5, size = 10, face = "bold"), legend.position = "none",
        legend.text = element_text(size = 5, color = "black"),
        legend.title = element_text(size = 5, color = "black"),
        panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank(),
        strip.text = element_text(vjust = 0.5, hjust=0.5, size = 5, color = "black"))

mmss_format <- function(x, ...) {
  sec <- x%%60
  min <- x%/%60
  sec <- base::sprintf("%05.2f", sec)
  ifelse(min == 0, paste(sec), 
         paste(min, sec, sep = ":"))
}

button_color_css <- "
#DivCompClear, #FinderClear, #EnterTimes{
/* Change the background color of the update button
to blue. */
background: DodgerBlue;
/* Change the text size to 15 pixels. */
font-size: 15px;
}"